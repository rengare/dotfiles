# NixOS System Configurations

This directory contains NixOS system configurations for various hosts, organized in a hosts-based structure.

## Structure

```
nixos/
├── flake.nix                    # Main flake with all host configurations
├── flake.lock                   # Lock file for reproducible builds (generated)
├── deploy.sh                    # Deployment helper script
├── .envrc                       # direnv configuration
├── CHANGELOG.md                 # Version history
├── docs/                        # Advanced guides
│   ├── SECRETS.md              # Secrets management guide
│   ├── HOME-MANAGER.md         # Home Manager integration
│   ├── VM-TESTING.md           # VM testing guide
│   └── github-actions-template.yml  # CI/CD template
├── modules/                     # Shared modules
│   ├── common.nix              # Common configuration for all hosts
│   ├── iso.nix                 # ISO installer-specific configuration
│   ├── users.nix               # Declarative user management module
│   ├── overlays.nix            # Custom packages and overrides
│   └── hardware-configuration-template.nix  # Template for new hosts
├── hosts/                       # Host-specific configurations
│   ├── example-x86/            # Example x86_64 host template
│   │   ├── configuration.nix
│   │   └── README.md
│   └── lenovo-t14s-x1e/        # Lenovo ThinkPad T14s Gen 6 (X1E)
│       ├── configuration.nix    # System configuration
│       ├── flake.nix           # Standalone flake (for backward compatibility)
│       └── README.md           # Detailed installation guide
├── README.md                    # This file
├── CONTRIBUTING.md             # Development and contribution guide
└── QUICKREF.md                 # Quick reference card
```

## Quick Start

See [QUICKREF.md](QUICKREF.md) for a quick reference card with common commands and patterns.

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed instructions on common operations.

### Using the Deploy Script

The `deploy.sh` helper script simplifies common operations:

```bash
./deploy.sh switch lenovo-t14s-x1e   # Switch to configuration
./deploy.sh iso lenovo-t14s-x1e      # Build installer ISO
./deploy.sh check                     # Run all checks
./deploy.sh update                    # Update dependencies
./deploy.sh fmt                       # Format code
./deploy.sh list                      # List available hosts
```

### Building an Installer ISO

Build a custom installer ISO with hardware-specific drivers:

```bash
# From the nixos directory
nix build .#packages.aarch64-linux.lenovo-t14s-x1e-iso

# ISO will be at: ./result/iso/lenovo-t14s-x1e-installer.iso
```

See [Building an Installer ISO](CONTRIBUTING.md#building-an-installer-iso) in CONTRIBUTING.md for details.

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

## Available Hosts

### lenovo-t14s-x1e
Lenovo ThinkPad T14s Gen 6 with Snapdragon X Elite (X1E) processor.

**Architecture:** `aarch64-linux`  
**Status:** Active configuration with full installation guide  
**Documentation:** [hosts/lenovo-t14s-x1e/README.md](hosts/lenovo-t14s-x1e/README.md)

## Common Configuration

All hosts import `modules/common.nix` which provides:

- **System State Version**: NixOS release tracking
- **Nix Settings**: Flakes, auto-optimization, garbage collection
- **Locale & Timezone**: Default to UTC and en_US.UTF-8 (override per-host)
- **Security Defaults**: Secure sudo configuration, polkit
- **Network**: NetworkManager enabled by default
- **Essential Packages**: vim, wget, curl, htop, and other utilities

Host-specific configurations can override these defaults using `lib.mkForce` or `lib.mkDefault`.

## ISO Builder

Each host automatically gets a corresponding installer ISO builder. The ISO includes:

- **Minimal NixOS installer** base
- **Hardware-specific drivers** for the target host
- **Installer tools**: partitioning, network, editors
- **SSH access** enabled (user: `nixos`, password: `nixos`)
- **Flake registry** with this repository pre-configured

Build an ISO:
```bash
nix build .#packages.aarch64-linux.lenovo-t14s-x1e-iso
# Result: ./result/iso/lenovo-t14s-x1e-installer.iso
```

See [CONTRIBUTING.md](CONTRIBUTING.md#building-an-installer-iso) for complete instructions.

## Adding a New Host

See [CONTRIBUTING.md](CONTRIBUTING.md#adding-a-new-host) for detailed instructions.

Quick summary:

1. Create directory: `mkdir -p hosts/my-hostname`
2. Generate hardware config on target machine
3. Create `configuration.nix`
4. Add to `flake.nix` nixosConfigurations
5. Build and test

## Updating

```bash
# Update flake inputs
cd nixos
nix flake update

# Apply updates
sudo nixos-rebuild switch --flake .#hostname
```

## Credits

The Lenovo T14s X1E configuration is built on top of the excellent work by **[kuruczgy](https://github.com/kuruczgy)** and their [x1e-nixos-config](https://github.com/kuruczgy/x1e-nixos-config) repository, which provides hardware support and drivers for Snapdragon X Elite devices on NixOS.

## Related Configurations

This repository also includes:
- **Home Manager configurations** in the `nix/` directory for user-level package management and dotfiles
- See the [root README](../README.md) for more information

## Documentation

- **[QUICKREF.md](QUICKREF.md)** - Quick reference card with commands and patterns
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Development guide and common operations
- **[CHANGELOG.md](CHANGELOG.md)** - Version history and changes
- **[modules/common.nix](modules/common.nix)** - Shared configuration reference
- **[modules/users.nix](modules/users.nix)** - Declarative user management
- **[modules/overlays.nix](modules/overlays.nix)** - Custom packages and overrides
- **Host-specific READMEs** in `hosts/*/README.md`:
  - [T14s X1E Guide](hosts/lenovo-t14s-x1e/README.md)
  - [x86_64 Template](hosts/example-x86/README.md)

### Advanced Guides

- **[docs/SECRETS.md](docs/SECRETS.md)** - Secrets management (sops-nix, agenix)
- **[docs/HOME-MANAGER.md](docs/HOME-MANAGER.md)** - Integrating Home Manager
- **[docs/VM-TESTING.md](docs/VM-TESTING.md)** - Testing configs in VMs
- **[docs/github-actions-template.yml](docs/github-actions-template.yml)** - CI/CD template

## Tools & Scripts

- **`deploy.sh`** - Helper script for common operations (switch, build, ISO, etc.)
- **`nix develop`** - Development shell with nixpkgs-fmt and nil (LSP)
- **`nix fmt`** - Format all nix files with nixpkgs-fmt
- **`nix flake check`** - Run all configuration checks

## Troubleshooting

See [CONTRIBUTING.md](CONTRIBUTING.md#troubleshooting) for common issues and solutions.

For host-specific troubleshooting, refer to the host's README:
- [T14s X1E Troubleshooting](hosts/lenovo-t14s-x1e/README.md#troubleshooting)

## License

See [LICENSE](../LICENSE) file for details.
