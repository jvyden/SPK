const std = @import("std");
const repo = @import("repo.zig");
const PackageMetadata = @import("types/package_file/package_metadata.zig");

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

    const name_length: u8 = try reader.readByte();
    const name: []u8 = try allocator.alloc(u8, name_length);
    defer allocator.free(name);
    _ = try reader.readAtLeast(name, name_length);
    std.log.debug("Package name ({} bytes): '{s}'", .{ name_length, name });

    const description_length: u8 = try reader.readByte();
    const description: []u8 = try allocator.alloc(u8, description_length);
    defer allocator.free(description);
    _ = try reader.readAtLeast(description, description_length);
    std.log.debug("Package description ({} bytes): '{s}'", .{ description_length, description });

    const semver_major: u8 = try reader.readByte();
    const semver_minor: u8 = try reader.readByte();
    const semver_patch: u8 = try reader.readByte();

    std.log.debug("Package version: {}.{}.{}", .{ semver_major, semver_minor, semver_patch });
}
