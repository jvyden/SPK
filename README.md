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