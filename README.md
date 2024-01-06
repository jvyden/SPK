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
- `spk info [spk-file]`
    Parses an SPK file's header and returns a JSON structure of the parsed data.

## Package format (.spk)
This is the format that package metadata and files will be shipped in

### Header
- Magic: `.SPK` in BE hex `0x2E53504B` `(u32)`
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

All files in the package will be extracted directly to the root of the filesystem *(or in the case of `spk extract`, `./package_name`)*.

## Installation metadata format (.spki)
This is how SPK records the list of installed packages, in addition to owned files and metadata such as who installed the package and when.

All installation metadata format files (henceforth referred to as simply SPKI) will be located at `/var/lib/spk/installed`, in accordance with the [Filesystem Hierarchy Standard Version 3.0](https://refspecs.linuxfoundation.org/FHS_3.0/fhs-3.0.html#varlibVariableStateInformation).

The file name will simply be the name of the installed package.

### Header
- Magic: `SPKI` in BE hex `0x53504B49` `(u32)`
- Format version `(u8)`
- Package metadata
  - Semver Major `(u8)`
  - Semver Minor `(u8)`
  - Semver Patch `(u8)`
- Installation metadata
  - Installing Effective User ID (EUID) `(u16)`
  - Original Installation date `(u64)`
  - Last update `(u64)`

### Owned files
TODO, basicalyl sha1 and relevant file paths