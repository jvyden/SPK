const PackageHeader = @import("package_file/package_header.zig");
const PackageFile = @import("package_file.zig");

header: PackageHeader,
file_count: u16,
file_table: []const PackageFile,
