const std = @import("std");

path: []const u8,
data_offset: u32,
data_length: u32,
fd: ?std.fs.File = null,

pub fn deinit(self: @This(), allocator: std.mem.Allocator) void {
    allocator.free(self.path);
    if (self.fd) |fd| fd.close();
}
