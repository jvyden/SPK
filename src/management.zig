const std = @import("std");
const repo = @import("repo.zig");
const PackageInfo = @import("types/package_info.zig");

const PackageManagementError = error{
    PackageNotFound,
};

pub fn installPackages(allocator: std.mem.Allocator, args: *std.process.ArgIterator) !void {
    var packages_in_repo = try repo.getPackages(allocator);
    defer packages_in_repo.deinit();

    while (args.next()) |package_name| {
        const package: ?PackageInfo = packages_in_repo.get(package_name) orelse return PackageManagementError.PackageNotFound;

        installPackage(package.?);
    }
}

fn installPackage(package: PackageInfo) void {
    std.log.debug("installing pkg {s}", .{package.name});
}
