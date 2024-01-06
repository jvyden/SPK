const std = @import("std");

pub fn getOrCreateDir(parent: std.fs.Dir, name: []const u8) !std.fs.Dir {
    parent.makeDir(name) catch |err| {
        if (err != error.PathAlreadyExists) return err;
    };

    return try parent.openDir(name, .{});
}
