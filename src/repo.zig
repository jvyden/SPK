const std = @import("std");
const PackageInfo = @import("types/package_info.zig");

pub fn getPackages(allocator: std.mem.Allocator) !std.StringHashMap(PackageInfo) {
    var package_map = std.StringHashMap(PackageInfo).init(allocator);

    try package_map.put("test", .{
        .name = "test",
        .description = "testing package",
    });

    return package_map;
}
