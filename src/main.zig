const std = @import("std");
const management = @import("./management.zig");

fn print_help(basename: []const u8) !void {
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

pub fn main() !u8 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var argIterator = std.process.args();
    const basename = argIterator.next() orelse unreachable;
    const action = argIterator.next() orelse {
        try print_help(basename);
        return 0;
    };

    if (std.mem.eql(u8, action, "install")) {
        try management.installPackages(gpa.allocator(), &argIterator);
        return 0;
    }

    std.debug.print("Error: Unknown action '{s}'.\n", .{action});
    try print_help(basename);
    return 1;
}
