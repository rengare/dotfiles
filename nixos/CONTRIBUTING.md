# Contributing to NixOS Configurations

This guide explains how to work with and contribute to these NixOS configurations.

## Table of Contents

- [Adding a New Host](#adding-a-new-host)
- [Common Operations](#common-operations)
- [Development Workflow](#development-workflow)
- [Module Organization](#module-organization)
- [Testing Changes](#testing-changes)

## Adding a New Host

### 1. Create Host Directory

```bash
mkdir -p nixos/hosts/your-hostname
```

### 2. Generate Hardware Configuration

Boot into NixOS installer on the target machine and run:

```bash
nixos-generate-config --show-hardware-config > hardware-configuration.nix
```

### 3. Create Configuration File

Create `nixos/hosts/your-hostname/configuration.nix`:

```nix
{ config, lib, pkgs, ... }:

{
  # Import hardware configuration
  imports = [ ./hardware-configuration.nix ];

  # Boot configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Filesystem configuration (if not in hardware-configuration.nix)
  fileSystems."/" = {
    device = "/dev/disk/by-label/root";
    fsType = "ext4";
  };

  # User configuration
  users.users.yourusername = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
  };

  # Add host-specific packages and configuration
  environment.systemPackages = with pkgs; [
    # your packages
  ];

  # Timezone (override common.nix default if needed)
  time.timeZone = "America/New_York";
}
```

### 4. Add to Flake

Edit `nixos/flake.nix` and add your host:

```nix
nixosConfigurations = {
  # ... existing hosts ...
  
  your-hostname = mkSystem {
    system = "x86_64-linux";  # or "aarch64-linux"
    hostname = "your-hostname";
    modules = [
      ./modules/common.nix
      ./hosts/your-hostname/configuration.nix
    ];
  };
};
```

## Common Operations

### Building a Configuration

```bash
# From the nixos directory
sudo nixos-rebuild switch --flake .#hostname

# Test without switching
sudo nixos-rebuild test --flake .#hostname

# Build without activating
sudo nixos-rebuild build --flake .#hostname
```

### Updating Dependencies

```bash
cd nixos
nix flake update          # Update all inputs
nix flake lock --update-input nixpkgs  # Update specific input
```

### Installing from Installer ISO

```bash
nixos-install --root /mnt --flake github:rengare/dotfiles?dir=nixos#hostname
```

### Rollback to Previous Generation

```bash
# List generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rollback
sudo nixos-rebuild switch --rollback
```

## Development Workflow

### 1. Make Changes

Edit configuration files in your text editor.

### 2. Check Syntax

```bash
# Check flake evaluation
nix flake check

# Show flake outputs
nix flake show
```

### 3. Test in VM (Optional)

```bash
nixos-rebuild build-vm --flake .#hostname
./result/bin/run-*-vm
```

### 4. Apply Changes

```bash
sudo nixos-rebuild switch --flake .#hostname
```

## Module Organization

### `modules/common.nix`

Shared configuration across all hosts:
- System state version
- Nix settings (flakes, garbage collection)
- Default locale and timezone
- Security defaults
- Common packages

To override common settings in a host, use `lib.mkForce`:

```nix
security.sudo.wheelNeedsPassword = lib.mkForce false;
```

### `modules/hardware-configuration-template.nix`

Template for hardware configurations. Not imported by default.

### Host-Specific Modules

Each host in `hosts/` should contain:
- `configuration.nix` - Main configuration
- `hardware-configuration.nix` - Hardware-specific settings (generated)
- Optional: `flake.nix` - Standalone flake for backward compatibility

## Testing Changes

### Syntax Check

```bash
nix flake check
```

### Dry Run

```bash
nixos-rebuild dry-build --flake .#hostname
```

### Build Without Activation

```bash
nixos-rebuild build --flake .#hostname
```

### Test in Current Session

```bash
nixos-rebuild test --flake .#hostname
```

This activates the new configuration but doesn't make it the boot default.

## Code Style

- Use 2 spaces for indentation
- Use `lib.mkDefault` for options that should be easily overridable
- Use `lib.mkForce` sparingly, only when you really need to override
- Add comments explaining non-obvious configuration
- Group related settings together

## Useful Commands

```bash
# Check what changed in the next rebuild
nixos-rebuild dry-activate --flake .#hostname

# Show package version
nix eval .#nixosConfigurations.hostname.config.environment.systemPackages

# Format nix files (if formatter is configured)
nix fmt

# Garbage collect old generations
sudo nix-collect-garbage --delete-older-than 30d

# Optimize nix store
sudo nix-store --optimise
```

## Getting Help

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [NixOS Wiki](https://nixos.wiki/)
- [Nix Pills](https://nixos.org/guides/nix-pills/)
- [NixOS Discourse](https://discourse.nixos.org/)

## Troubleshooting

### Configuration Fails to Build

1. Check syntax: `nix flake check`
2. Review error messages carefully
3. Try building a minimal configuration first
4. Check if all imported files exist

### System Won't Boot

1. Boot into previous generation from bootloader
2. Check system logs: `journalctl -xb`
3. Use `nixos-rebuild switch --rollback`

### Flake Lock Issues

If you get lock file errors:

```bash
nix flake lock --update-input nixpkgs
# or
rm flake.lock && nix flake update
```
