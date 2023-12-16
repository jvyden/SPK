const PackageHeader = @import("package_file/package_header.zig");
const PackageFile = @import("package_file/package_file.zig");
const std = @import("std");

header: PackageHeader,
file_table: []const PackageFile,

const Self = @This();

fn readString(comptime T: type, allocator: std.mem.Allocator, reader: anytype) ![]u8 {
    const str_length: T = try reader.readInt(T, .little);
    const str: []u8 = try allocator.alloc(u8, str_length);

    _ = try reader.readAtLeast(str, str_length);
    return str;
}

pub fn fromReader(allocator: std.mem.Allocator, reader: std.io.AnyReader) !Self {
    const magic: u32 = try reader.readInt(u32, .big);
    if (magic != 0x2E53504B) {
        // return PackageManagementError.InvalidMagic;
    }

    const format_version: u8 = try reader.readByte();
    std.log.debug("Format version: {}", .{format_version});

    const name: []u8 = try readString(u8, allocator, reader);
    // defer allocator.free(name);
    std.log.debug("Package name: '{s}'", .{name});

    const description: []u8 = try readString(u8, allocator, reader);
    // defer allocator.free(description);
    std.log.debug("Package description: '{s}'", .{description});

    const semver_major: u8 = try reader.readByte();
    const semver_minor: u8 = try reader.readByte();
    const semver_patch: u8 = try reader.readByte();
    std.log.debug("Package version: {}.{}.{}", .{ semver_major, semver_minor, semver_patch });

    const file_count: u16 = try reader.readInt(u16, .little);
    std.log.debug("File count: {}", .{file_count});

    const files: []PackageFile = try allocator.alloc(PackageFile, file_count);
    // defer allocator.free(files);

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

fn fileTableEntryFromReader(allocator: std.mem.Allocator, reader: anytype) !PackageFile {
    const path: []u8 = try readString(u16, allocator, reader);
    // defer allocator.free(path);
    // std.log.debug("File path ({} bytes): '{s}'", .{ path.len, path });

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
        allocator.free(file.path);
    }

    allocator.free(self.file_table);
    allocator.free(self.header.package_metadata.name);
    allocator.free(self.header.package_metadata.description);
}
