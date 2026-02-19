# Hardware configuration template
# This file should be generated using: nixos-generate-config --show-hardware-config
# 
# For new hosts:
# 1. Boot into the NixOS installer
# 2. Run: nixos-generate-config --show-hardware-config > hardware-configuration.nix
# 3. Review and adjust as needed
# 4. Import this file in your host's configuration.nix

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ ];

  # Example boot configuration
  # boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
  # boot.kernelModules = [ ];
  
  # Example filesystem configuration
  # fileSystems."/" = {
  #   device = "/dev/disk/by-label/root";
  #   fsType = "ext4";
  # };
  
  # fileSystems."/boot" = {
  #   device = "/dev/disk/by-label/boot";
  #   fsType = "vfat";
  # };
  
  # Swap configuration (optional)
  # swapDevices = [ ];
  
  # CPU and hardware settings
  # nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  # hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
