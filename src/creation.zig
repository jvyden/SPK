const std = @import("std");
const Package = @import("types/package.zig");
const PackageFile = @import("types/package_file//package_file.zig");

pub fn printInfoForPackageFile(allocator: std.mem.Allocator, package_filename: []const u8) !void {
    const file = try std.fs.cwd().openFile(package_filename, .{ .mode = .read_only });
    defer file.close();

    const reader = file.reader();

    const package: Package = try Package.fromReader(allocator, reader.any());
    defer package.deinit(allocator);
    std.log.info("{s}", .{std.json.fmt(package, .{ .whitespace = .indent_2 })});
}

fn addFilesFromDirectory(allocator: std.mem.Allocator, path: []const u8, dir: std.fs.Dir, files: *std.ArrayList(PackageFile)) !void {
    var it = dir.iterate();
    while (try it.next()) |item| {
        const qualifiedPath = try std.fs.path.join(allocator, &.{ path, item.name });
        defer allocator.free(qualifiedPath);

        std.log.debug("Adding {s} {s} to package...", .{ @tagName(item.kind), qualifiedPath });
        if (item.kind == .directory) {
            var sub_dir = try dir.openDir(item.name, .{ .iterate = true });
            defer sub_dir.close();

            try addFilesFromDirectory(allocator, qualifiedPath, sub_dir, files);
        } else if (item.kind == .file) {
            const fd = try dir.openFile(item.name, .{});

            try files.append(.{
                .path = try allocator.dupe(u8, qualifiedPath),
                .data_length = @intCast((try fd.stat()).size),
                .data_offset = 0,
                .fd = fd,
            });
        }
    }
}

pub fn createPackageFileFromDirectory(allocator: std.mem.Allocator, package_root: []const u8) !void {
    var root_dir = try std.fs.cwd().openDir(package_root, .{ .iterate = true });

    var files = std.ArrayList(PackageFile).init(allocator);
    defer files.deinit();

    try addFilesFromDirectory(allocator, "/", root_dir, &files);
    defer root_dir.close();

    const package_name: []const u8 = "pkg";
    _ = package_name;

    const files_slice = try files.toOwnedSlice();
    defer allocator.free(files_slice);
    defer for (files_slice) |file| {
        file.deinit(allocator);
    };

    const package: Package = .{
        .header = .{
            .magic = Package.header_magic,
            .format_version = 1,
            .package_metadata = .{
                .name = "obama", // TODO, duh.
                .description = "presidential",
                .semver_major = 4,
                .semver_minor = 2,
                .semver_patch = 0,
            },
        },
        .file_table = files_slice,
    };

    var file = try std.fs.cwd().createFile("pkg.spk", .{});
    defer file.close();

    try package.toWriter(file.writer());
}
