const std = @import("std");
const repo = @import("repo.zig");
const PackageMetadata = @import("types/package_file/package_metadata.zig");
const PackageFile = @import("types/package_file/package_file.zig");

const PackageManagementError = error{
    PackageNotFound,
    InvalidMagic,
};

pub fn installPackages(allocator: std.mem.Allocator, args: *std.process.ArgIterator) !void {
    var packages_in_repo = try repo.getPackages(allocator);
    defer packages_in_repo.deinit();

    while (args.next()) |package_name| {
        const package: ?PackageMetadata = packages_in_repo.get(package_name) orelse return PackageManagementError.PackageNotFound;

        installPackage(package.?);
    }
}

fn installPackage(package: PackageMetadata) void {
    std.log.debug("installing pkg {s}@{}.{}.{}", .{ package.name, package.semver_major, package.semver_minor, package.semver_patch });
}

pub fn printInfoForPackageFile(allocator: std.mem.Allocator, package_filename: []const u8) !void {
    const file = try std.fs.cwd().openFile(package_filename, .{ .mode = .read_only });
    defer file.close();

    const reader = file.reader();
    const magic: u32 = try reader.readInt(u32, .big);
    if (magic != 0x2E53504B) {
        return PackageManagementError.InvalidMagic;
    }

    const format_version: u8 = try reader.readByte();
    std.log.debug("Format version: {}", .{format_version});

    const name: []u8 = try readString(u8, allocator, reader);
    defer allocator.free(name);
    std.log.debug("Package name: '{s}'", .{name});

    const description: []u8 = try readString(u8, allocator, reader);
    defer allocator.free(description);
    std.log.debug("Package description: '{s}'", .{description});

    const semver_major: u8 = try reader.readByte();
    const semver_minor: u8 = try reader.readByte();
    const semver_patch: u8 = try reader.readByte();
    std.log.debug("Package version: {}.{}.{}", .{ semver_major, semver_minor, semver_patch });

    const file_count: u16 = try reader.readInt(u16, .little);
    std.log.debug("File count: {}", .{file_count});

    const files: []PackageFile = try allocator.alloc(PackageFile, file_count);
    defer allocator.free(files);

    for (0..file_count) |i| {
        files[i] = try printFileTableEntryForPackageFile(allocator, reader);
    }

    // TODO: error if not at end of file
}

fn readString(comptime T: type, allocator: std.mem.Allocator, reader: anytype) ![]u8 {
    const str_length: T = try reader.readInt(T, .little);
    const str: []u8 = try allocator.alloc(u8, str_length);

    _ = try reader.readAtLeast(str, str_length);
    return str;
}

fn printFileTableEntryForPackageFile(allocator: std.mem.Allocator, reader: anytype) !PackageFile {
    const path: []u8 = try readString(u16, allocator, reader);
    defer allocator.free(path);
    // std.log.debug("File path ({} bytes): '{s}'", .{ path.len, path });

    const data_offset: u32 = try reader.readInt(u32, .little);
    const data_length: u32 = try reader.readInt(u32, .little);

    std.log.debug("File {s}: {} bytes @ 0x{x}", .{ path, data_length, data_offset });

    return .{
        .path = path,
        .data_offset = data_offset,
        .data_length = data_length,
    };
}
