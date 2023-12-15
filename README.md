# SPK - Simple PacKage manager

A simple Linux package manager written in Zig.

## Commands

### Management
- `spk install [package]`
    Installs a package.
- `spk remove|uninstall [package]`
    Removes a package from the system.
- `spk ls`
    Lists currently installed packages.
- `spk search [query]`
    Searches your repository cache for packages by their names and descriptions.

### Creation
- `spk create [package-root]`
    Creates a package file from the directory specified in `[package-root]`.
- `spk create-init [package-root] [name]`
    Initializes an empty package with a blank manifest in the `[package-root]` with the given name.

## Package format (.spk)

### Header

- Magic: `.SPK` in hex `0x2E53504B` `(u32)`
- Format version `(u8)`
- Package metadata
  - Name length `(u8)`
  - Name string `([]const u8)`
  - Description length `(u8)`
  - Description string `([]const u8)`
  - Semver Major `(u8)`
  - Semver Minor `(u8)`
  - Semver Patch `(u8)`

### Files

- File count `(u16)`
- File table
  - Path length `(u16)`
  - Path string `([]const u8)`
  - Data offset `(u32)`
  - Data length `(u32)`


### Hierarchy

There is no real significant hierarchy for files in the File table.

All files in the package will be extracted directly to the root of the filesystem.