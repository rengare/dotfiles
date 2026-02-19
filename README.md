# Dotfiles

Personal dotfiles and configuration files for various systems and applications.

## Repository Structure

- **`.config/`** - Application configuration files (following XDG Base Directory specification)
- **`home_config/`** - Additional home directory configuration files
- **`misc/`** - Miscellaneous configuration and helper files
- **`nix/`** - Nix and Home Manager configurations for managing user environments
  - `linux/` - Linux-specific Home Manager configuration
  - `darwin/` - macOS-specific Home Manager configuration
  - `flake.nix` - Main flake for Home Manager configurations
- **`nixos/`** - NixOS system configurations
  - `flake.nix` - Main flake for NixOS system configurations
  - `hosts/` - Host-specific system configurations
    - `lenovo-t14s-x1e/` - **NixOS configuration for Lenovo ThinkPad T14s Gen 6 (Snapdragon X Elite)**
      - See [detailed installation guide](nixos/hosts/lenovo-t14s-x1e/README.md)
  - See [NixOS README](nixos/README.md) for more information
- **`scripts/`** - Utility scripts
- **`theme/`** - Theming configurations

## NixOS for Lenovo ThinkPad T14s X1E

This repository now includes a complete NixOS configuration for the **Lenovo ThinkPad T14s Gen 6** with Snapdragon X Elite (X1E) processor.

### Credits

This configuration is built on top of the excellent work by **[kuruczgy](https://github.com/kuruczgy)** and their [x1e-nixos-config](https://github.com/kuruczgy/x1e-nixos-config) repository, which provides hardware support and drivers for Snapdragon X Elite devices on NixOS. All credit for the hardware enablement goes to kuruczgy and the contributors of that project.

### Quick Start

For detailed installation instructions, see: [nixos/hosts/lenovo-t14s-x1e/README.md](nixos/hosts/lenovo-t14s-x1e/README.md)

**Key Features:**
- Based on [kuruczgy/x1e-nixos-config](https://github.com/kuruczgy/x1e-nixos-config)
- Full hardware support for T14s X1E
- Dual-boot ready (Windows + NixOS)
- Complete installation guide from ISO compilation to first boot

**Installation Summary:**
1. Build the minimal NixOS ISO (via x86_64 cross-compile or WSL on device)
2. Prepare your system (optional: shrink Windows partition for dual-boot)
3. Boot from USB and install NixOS
4. Configure EFI boot entries

For the complete step-by-step guide with all details, troubleshooting, and customization options, see the [detailed README](nixos/hosts/lenovo-t14s-x1e/README.md).

## Home Manager Configurations

The repository includes Home Manager configurations for:

- **Linux (x86_64)**: `ren-linux`
- **Linux (aarch64)**: `ren-linux-arm`  
- **macOS (x86_64)**: `ren-darwin`

### Using Home Manager

```bash
# Clone the repository
git clone https://github.com/rengare/dotfiles.git
cd dotfiles/nix

# Build and activate configuration
home-manager switch --flake .#ren-linux
```

## License

See [LICENSE](LICENSE) file for details.
