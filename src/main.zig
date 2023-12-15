const std = @import("std");

pub fn print_help(basename: []const u8) !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("SPK: Simple PacKage manager\n", .{});

    try stdout.print("\nManagement:\n", .{});
    try print_help_cmd(stdout, basename, "install", "Installs a package.");
    try print_help_cmd(stdout, basename, "remove|uninstall", "Removes a package from the system.");
    try print_help_cmd(stdout, basename, "ls", "Lists currently installed packages.");
    try print_help_cmd(stdout, basename, "search", "Searches your repository cache for packages by their names and descriptions.");

    try stdout.print("\nCreation:\n", .{});
    try print_help_cmd(stdout, basename, "create", "Creates a package file from the directory specified in `[package-root]`.");
    try print_help_cmd(stdout, basename, "create-init", "Initializes an empty package with a blank manifest in the `[package-root]` with the given name.");
}

fn print_help_cmd(out: anytype, basename: []const u8, comptime action: []const u8, comptime description: []const u8) !void {
    try out.print("  {s} {s}: {s}\n", .{ basename, action, description });
}

pub fn main() !void {
    // try stdout.print("Run `zig build test` to run the tests.\n", .{});

    // const allocator: std.mem.Allocator = std.heap.GeneralPurposeAllocator(.{});
    // _ = allocator;

    var argIterator = std.process.args();
    const basename = argIterator.next() orelse unreachable;
    const action = argIterator.next() orelse return try print_help(basename);

    std.debug.print("yo man, you called me with the action '{s}'\n", .{action});
}
