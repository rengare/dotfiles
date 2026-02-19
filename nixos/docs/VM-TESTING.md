# VM Testing Guide

Testing NixOS configurations in a virtual machine before deploying to real hardware.

## Quick Start

```bash
# Build and run VM for a host
nixos-rebuild build-vm --flake .#lenovo-t14s-x1e

# Run the VM
./result/bin/run-*-vm

# Or use the deploy script
./deploy.sh build-vm lenovo-t14s-x1e  # (after adding this command)
```

## VM Configuration

Add VM-specific overrides to your host configuration:

```nix
# hosts/my-host/configuration.nix
{ config, lib, pkgs, modulesPath, ... }:

{
  # Your normal configuration...
  
  # VM-specific settings (only active when building VM)
  virtualisation.vmVariant = {
    # Allocate more resources for testing
    virtualisation = {
      memorySize = 4096;  # 4GB RAM
      cores = 4;
      diskSize = 20480;   # 20GB disk
      
      # Share a directory with host
      sharedDirectories = {
        home = {
          source = "$HOME/vm-shared";
          target = "/mnt/shared";
        };
      };
    };
    
    # Enable graphics
    virtualisation.qemu.options = [
      "-vga virtio"
      "-display gtk,zoom-to-fit=on"
    ];
  };
}
```

## Testing Workflow

### 1. Build VM
```bash
nixos-rebuild build-vm --flake .#my-host
```

### 2. Run and Test
```bash
# Start VM
./result/bin/run-my-host-vm

# Inside VM:
# - Test services
# - Check configurations
# - Verify packages
# - Test user setup
```

### 3. Iterate
```bash
# Make changes to configuration
vim hosts/my-host/configuration.nix

# Rebuild VM
nixos-rebuild build-vm --flake .#my-host

# Test again
./result/bin/run-my-host-vm
```

## VM Variants for Different Tests

### Minimal VM (faster builds)
```nix
virtualisation.vmVariant = {
  # Disable GUI
  services.xserver.enable = lib.mkForce false;
  
  # Minimal packages
  environment.systemPackages = lib.mkForce (with pkgs; [
    vim git
  ]);
  
  # Smaller disk
  virtualisation.diskSize = 8192;
};
```

### Desktop Testing VM
```nix
virtualisation.vmVariant = {
  # More resources
  virtualisation.memorySize = 8192;
  virtualisation.cores = 8;
  
  # Enable graphics
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
};
```

### Network Service Testing
```nix
virtualisation.vmVariant = {
  # Forward ports
  virtualisation.forwardPorts = [
    { from = "host"; host.port = 8080; guest.port = 80; }
    { from = "host"; host.port = 2222; guest.port = 22; }
  ];
  
  # Enable SSH
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";
  users.users.root.password = "test";
};
```

## Automated VM Tests

Create a test module:

```nix
# hosts/my-host/tests/basic.nix
{ pkgs, ... }:

{
  # This creates a VM test that runs automatically
  # and checks if everything works
  
  virtualisation.vmVariant.test = {
    nodes.machine = { config, pkgs, ... }: {
      imports = [ ../configuration.nix ];
    };
    
    testScript = ''
      machine.wait_for_unit("multi-user.target")
      machine.succeed("systemctl status sshd")
      machine.succeed("which git")
      machine.succeed("which vim")
    '';
  };
}
```

## NixOS Test Framework

For more comprehensive testing:

```nix
# tests/integration.nix
import <nixpkgs/nixos/tests/make-test-python.nix> ({ pkgs, ... }: {
  name = "my-host-integration";
  
  nodes.machine = { config, pkgs, ... }: {
    imports = [ ../hosts/my-host/configuration.nix ];
  };
  
  testScript = ''
    start_all()
    
    machine.wait_for_unit("multi-user.target")
    machine.succeed("systemctl --no-pager status")
    
    # Test user creation
    machine.succeed("id alice")
    
    # Test network
    machine.wait_for_unit("network.target")
    machine.succeed("ping -c 1 example.com")
    
    # Test services
    machine.wait_for_unit("sshd.service")
    machine.succeed("ss -tulpn | grep :22")
    
    # Take screenshot
    machine.screenshot("final_state")
  '';
})
```

Run with:
```bash
nix-build tests/integration.nix
```

## Tips

1. **Use snapshots**: QEMU supports snapshots for quick rollback
2. **Share folders**: Use shared directories to exchange files
3. **Port forwarding**: Access services from host
4. **Headless mode**: Use `-nographic` for faster testing
5. **Automation**: Write test scripts to verify config

## Common Issues

### VM won't start
```bash
# Check if virtualization is enabled
grep -E 'vmx|svm' /proc/cpuinfo

# Try with less resources
virtualisation.memorySize = 2048;
```

### Graphics issues
```bash
# Use different display backend
virtualisation.qemu.options = [ "-display sdl" ];
# Or
virtualisation.qemu.options = [ "-nographic" ];
```

### Slow performance
```bash
# Enable KVM acceleration
virtualisation.qemu.options = [ "-enable-kvm" ];
```

## See Also

- [NixOS VM Testing](https://nixos.org/manual/nixos/stable/index.html#sec-nixos-tests)
- [QEMU Documentation](https://www.qemu.org/docs/master/)
- `nixpkgs/nixos/tests/` - Example tests in nixpkgs
