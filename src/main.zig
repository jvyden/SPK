const std = @import("std");
const management = @import("./management.zig");
const creation = @import("./creation.zig");

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
    try print_help_cmd(stdout, basename, "info", "Parses an SPK file's header and returns a JSON structure of the parsed data.");
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

    const cliResult: bool = invokeCliCommand(action, gpa.allocator(), &argIterator) catch |err| {
        std.log.err("error while invoking cli: {!}", .{err});
        return 2;
    };

    if (cliResult) return 0;

    std.log.err("Unknown action '{s}'", .{action});
    try print_help(basename);
    return 1;
}

fn invokeCliCommand(action: []const u8, allocator: std.mem.Allocator, args: *std.process.ArgIterator) !bool {
    if (std.mem.eql(u8, action, "install")) {
        try management.installPackages(allocator, args);
    } else if (std.mem.eql(u8, action, "info")) {
        const package = args.next();
        if (package == null) return false;

        try creation.printInfoForPackageFile(allocator, package.?);
    } else if (std.mem.eql(u8, action, "create")) {
        const package_root = args.next();
        if (package_root == null) return false;

        try creation.createPackageFileFromDirectory(allocator, package_root.?);
    } else {
        return false;
    }

    return true;
}
