const std = @import("std");

pub fn install(args: *std.process.ArgIterator) !void {
    var package_name: ?[]const u8 = args.next();
    while (package_name != null) {
        install_package(package_name.?);
        package_name = args.next();
    }
}

fn install_package(package_name: []const u8) void {
    std.debug.print("install pkg {s}\n", .{package_name});
}
