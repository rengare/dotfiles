# NixOS System Configurations

This directory contains NixOS system configurations for various hosts, organized in a hosts-based structure.

## Structure

```
nixos/
├── flake.nix                    # Main flake with all host configurations
├── hosts/                       # Host-specific configurations
│   └── lenovo-t14s-x1e/        # Lenovo ThinkPad T14s Gen 6 (X1E)
│       ├── configuration.nix    # System configuration
│       ├── flake.nix           # Standalone flake (for backward compatibility)
│       └── README.md           # Detailed installation guide
└── README.md                    # This file
```

## Available Hosts

### lenovo-t14s-x1e
Lenovo ThinkPad T14s Gen 6 with Snapdragon X Elite (X1E) processor.

**Architecture:** `aarch64-linux`  
**Status:** Active configuration with full installation guide  
**Documentation:** [hosts/lenovo-t14s-x1e/README.md](hosts/lenovo-t14s-x1e/README.md)

## Usage

### Installing NixOS from this repository

```bash
# From the nixos directory, install a specific host configuration
nixos-install --root /mnt --no-channel-copy --no-root-password \
  --flake .#lenovo-t14s-x1e

# Or from the repository root
nixos-install --root /mnt --no-channel-copy --no-root-password \
  --flake github:rengare/dotfiles?dir=nixos#lenovo-t14s-x1e
```

### Rebuilding an existing system

```bash
# From the nixos directory
sudo nixos-rebuild switch --flake .#lenovo-t14s-x1e

# Or from the repository root
sudo nixos-rebuild switch --flake ./nixos#lenovo-t14s-x1e
```

## Adding a New Host

To add a new host configuration:

1. Create a new directory under `hosts/`:
   ```bash
   mkdir -p hosts/my-hostname
   ```

2. Create a `configuration.nix` in that directory with your system configuration.

3. Add the host to `flake.nix`:
   ```nix
   nixosConfigurations.my-hostname = nixpkgs.lib.nixosSystem {
     system = "x86_64-linux";  # or aarch64-linux
     modules = [
       ./hosts/my-hostname/configuration.nix
     ];
   };
   ```

4. (Optional) Create a standalone `flake.nix` in the host directory for backward compatibility.

## Credits

The Lenovo T14s X1E configuration is built on top of the excellent work by **[kuruczgy](https://github.com/kuruczgy)** and their [x1e-nixos-config](https://github.com/kuruczgy/x1e-nixos-config) repository, which provides hardware support and drivers for Snapdragon X Elite devices on NixOS.

## Related Configurations

This repository also includes:
- **Home Manager configurations** in the `nix/` directory for user-level package management and dotfiles
- See the [root README](../README.md) for more information

## License

See [LICENSE](../LICENSE) file for details.
