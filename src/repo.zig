const std = @import("std");
const PackageMetadata = @import("types/package_file/package_metadata.zig");

pub fn getPackages(allocator: std.mem.Allocator) !std.StringHashMap(PackageMetadata) {
    var package_map = std.StringHashMap(PackageMetadata).init(allocator);

    try package_map.put("test", .{
        .name = "test",
        .description = "testing package",
        .semver_major = 1,
        .semver_minor = 0,
        .semver_patch = 0,
    });

    return package_map;
}
