const std = @import("std");
const utils = @import("utils.zig");
const repo = @import("repo.zig");
const Package = @import("types/package.zig");
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

pub fn extractPackageToCwdFromFile(allocator: std.mem.Allocator, package_filename: []const u8) !void {
    const package: Package = try Package.fromCwdFile(allocator, package_filename);
    defer package.deinit(allocator);

    const package_name = package.header.package_metadata.name;

    std.log.debug("Attempting to create folder for package at '{s}'", .{package_name});
    const dir: std.fs.Dir = try utils.getOrCreateDir(std.fs.cwd(), package_name);
    _ = dir;

    var file_index: u16 = 1; // Starts at one - this string is only for user output
    for (package.file_table) |file| {
        std.log.info("Extracting file {}/{} '{s}' ({} bytes)", .{ file_index, package.file_table.len, file.path, file.data_offset });
        file_index += 1;
    }

    std.log.info("Successfully extracted all files from archive.", .{});
}
