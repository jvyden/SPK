const std = @import("std");
const repo = @import("repo.zig");
const PackageMetadata = @import("types/package_file/package_metadata.zig");
const Package = @import("types/package.zig");

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

    const package: Package = try Package.fromReader(allocator, reader.any());
    defer package.deinit(allocator);
    std.log.info("{s}", .{std.json.fmt(package, .{ .whitespace = .indent_2 })});
}
