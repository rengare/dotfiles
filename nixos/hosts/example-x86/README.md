# Example x86_64 Host Configuration

This is an example/template configuration for x86_64 systems.

## Using This Template

1. **Copy this directory:**
   ```bash
   cp -r hosts/example-x86 hosts/my-hostname
   ```

2. **Generate hardware configuration:**
   ```bash
   nixos-generate-config --show-hardware-config > hosts/my-hostname/hardware-configuration.nix
   ```

3. **Edit configuration.nix:**
   - Uncomment and adjust filesystem paths
   - Configure users
   - Add required services
   - Set timezone if different from UTC

4. **Add to flake.nix:**
   ```nix
   nixosConfigurations.my-hostname = mkSystem {
     system = "x86_64-linux";
     hostname = "my-hostname";
     modules = [
       ./modules/common.nix
       ./hosts/my-hostname/configuration.nix
     ];
   };

   my-hostname-iso = mkISO {
     system = "x86_64-linux";
     hostname = "my-hostname";
     modules = [];
   };
   ```

5. **Add to packages output:**
   ```nix
   packages = forAllSystems (system: {
     # ... existing packages ...
     my-hostname-iso = self.nixosConfigurations.my-hostname-iso.config.system.build.isoImage;
   });
   ```

6. **Test the configuration:**
   ```bash
   nixos-rebuild build --flake .#my-hostname
   ```

## Features Included

- ✓ systemd-boot bootloader
- ✓ Example filesystems (ext4 root, vfat boot)
- ✓ Declarative user management example
- ✓ Common packages from common.nix
- ✓ NetworkManager enabled
- ✓ Firewall enabled by default

## Common Customizations

### Desktop Environment

Uncomment in configuration.nix:
```nix
services.xserver = {
  enable = true;
  displayManager.gdm.enable = true;
  desktopManager.gnome.enable = true;
};
```

### Development Environment

```nix
environment.systemPackages = with pkgs; [
  vim git gcc python3 nodejs
];
services.docker.enable = true;
virtualisation.libvirtd.enable = true;
```

### Server Configuration

```nix
services.openssh = {
  enable = true;
  settings.PasswordAuthentication = false;
};
networking.firewall.allowedTCPPorts = [ 22 80 443 ];
```

## See Also

- [QUICKREF.md](../../QUICKREF.md) - Quick reference guide
- [CONTRIBUTING.md](../../CONTRIBUTING.md) - Detailed contribution guide
- [Lenovo T14s X1E config](../lenovo-t14s-x1e/) - Real-world ARM64 example
