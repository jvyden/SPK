const PackageHeader = @import("package_file/package_header.zig");
const PackageFile = @import("package_file/package_file.zig");
const std = @import("std");

header: PackageHeader,
file_table: []const PackageFile,

const ParseError = error{
    InvalidMagic,
};

pub const header_magic: comptime_int = 0x2E53504B; // ".SPK"

const Self = @This();

fn readString(comptime T: type, allocator: std.mem.Allocator, reader: anytype) ![]u8 {
    const str_length: T = try reader.readInt(T, .little);
    const str: []u8 = try allocator.alloc(u8, str_length);

    _ = try reader.readAtLeast(str, str_length);
    return str;
}

pub fn fromReader(allocator: std.mem.Allocator, reader: std.io.AnyReader) !Self {
    const magic: u32 = try reader.readInt(u32, .big);
    if (magic != header_magic) {
        return ParseError.InvalidMagic;
    }

    const format_version: u8 = try reader.readByte();
    std.log.debug("Format version: {}", .{format_version});

    const name: []u8 = try readString(u8, allocator, reader);
    std.log.debug("Package name: '{s}'", .{name});

    const description: []u8 = try readString(u8, allocator, reader);
    std.log.debug("Package description: '{s}'", .{description});

    const semver_major: u8 = try reader.readByte();
    const semver_minor: u8 = try reader.readByte();
    const semver_patch: u8 = try reader.readByte();
    std.log.debug("Package version: {}.{}.{}", .{ semver_major, semver_minor, semver_patch });

    const file_count: u16 = try reader.readInt(u16, .little);
    std.log.debug("File count: {}", .{file_count});

    const files: []PackageFile = try allocator.alloc(PackageFile, file_count);

    for (0..file_count) |i| {
        files[i] = try fileTableEntryFromReader(allocator, reader);
    }

    return .{
        .header = .{
            .magic = magic,
            .format_version = format_version,
            .package_metadata = .{
                .name = name,
                .description = description,
                .semver_major = semver_major,
                .semver_minor = semver_minor,
                .semver_patch = semver_patch,
            },
        },
        .file_table = files,
    };
}

pub fn toWriter(self: Self, fs_writer: std.fs.File.Writer) !void {
    var countingWriter = std.io.countingWriter(fs_writer);
    var writer = countingWriter.writer();

    try writer.writeInt(u32, header_magic, .big);
    try writer.writeByte(self.header.format_version);

    try writer.writeByte(@intCast(self.header.package_metadata.name.len));
    try writer.writeAll(self.header.package_metadata.name);

    try writer.writeByte(@intCast(self.header.package_metadata.description.len));
    try writer.writeAll(self.header.package_metadata.description);

    try writer.writeByte(self.header.package_metadata.semver_major);
    try writer.writeByte(self.header.package_metadata.semver_minor);
    try writer.writeByte(self.header.package_metadata.semver_patch);

    try writer.writeInt(u16, @intCast(self.file_table.len), .little);

    const package_file_size: comptime_int = @sizeOf(u32) + @sizeOf(u32) + @sizeOf(u16);

    // The minimum offset a new file can be added at.
    var minimum_offset: u64 = countingWriter.bytes_written + (package_file_size * self.file_table.len);

    // Add sizes of path to offset
    for (self.file_table) |file| {
        minimum_offset += file.path.len;
    }

    // Write the file table
    for (self.file_table) |file| {
        try writer.writeInt(u16, @intCast(file.path.len), .little);
        try writer.writeAll(file.path);

        try writer.writeInt(u32, @intCast(minimum_offset), .little);
        try writer.writeInt(u32, file.data_length, .little);

        minimum_offset += file.data_length;
    }

    // Write the files in the file table
    for (self.file_table) |file| {
        const fd = file.fd.?;
        var buf: [4096]u8 = undefined;

        while (blk: {
            const read = try fd.read(&buf);
            if (read == 0) break :blk null;
            break :blk read;
        }) |read| {
            const data = buf[0..read];
            try writer.writeAll(data);
        }
    }
}

fn fileTableEntryFromReader(allocator: std.mem.Allocator, reader: anytype) !PackageFile {
    const path: []u8 = try readString(u16, allocator, reader);

    const data_offset: u32 = try reader.readInt(u32, .little);
    const data_length: u32 = try reader.readInt(u32, .little);

    std.log.debug("File {s}: {} bytes @ 0x{X}", .{ path, data_length, data_offset });

    return .{
        .path = path,
        .data_offset = data_offset,
        .data_length = data_length,
    };
}

pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
    for (self.file_table) |file| {
        file.deinit(allocator);
    }

    allocator.free(self.file_table);
    allocator.free(self.header.package_metadata.name);
    allocator.free(self.header.package_metadata.description);
}
