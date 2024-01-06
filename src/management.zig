const std = @import("std");
const utils = @import("utils.zig");
const repo = @import("repo.zig");
const Package = @import("types/package.zig");
const PackageMetadata = @import("types/package_file/package_metadata.zig");

const PackageManagementError = error{
    PackageNotFound,
    InvalidMagic,
    NoFilesInPackage,
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
    const package_file = try std.fs.cwd().openFile(package_filename, .{ .mode = .read_only });
    defer package_file.close();

    const reader = package_file.reader();

    // read the package
    const package: Package = try Package.fromReader(allocator, reader.any());
    defer package.deinit(allocator);

    const package_name = package.header.package_metadata.name;

    // create a folder to extract the files to
    std.log.debug("Attempting to create folder for package at '{s}'", .{package_name});
    const package_dir: std.fs.Dir = try utils.getOrCreateDir(std.fs.cwd(), package_name);

    // ensure this package has atleast one file
    if (package.file_table.len < 1) {
        return PackageManagementError.NoFilesInPackage;
    }

    var file_index: u16 = 1; // Starts at one - this string is only for user output
    for (package.file_table) |file_metadata| {
        std.log.info("Extracting file {}/{} '{s}' ({} bytes)", .{ file_index, package.file_table.len, file_metadata.path, file_metadata.data_offset });

        // ugly hack to skip '/' in path. TODO: fix this in package format v2
        const file: std.fs.File = try package_dir.createFile(file_metadata.path[1..], .{});
        defer file.close();

        const writer = file.writer();

        // since we've already read the header with this reader, we should be at the right offset
        // FIXME: ew, we allocate the whole fucking file here. bad bad bad we should stream this instead
        const buffer: []u8 = try allocator.alloc(u8, file_metadata.data_length);
        defer allocator.free(buffer);

        _ = try reader.readAtLeast(buffer, file_metadata.data_length);
        try writer.writeAll(buffer);

        file_index += 1;
    }

    std.log.info("Successfully extracted all files from archive.", .{});
}
