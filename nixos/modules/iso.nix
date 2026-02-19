# ISO-specific configuration
# This module is imported when building installer ISOs
{ config, pkgs, lib, ... }:

{
  # Use a minimal ISO base
  # The actual import happens in flake.nix
  
  # Disable ZFS and CIFS support to reduce ISO size
  boot.supportedFilesystems.zfs = lib.mkForce false;
  boot.supportedFilesystems.cifs = lib.mkForce false;
  
  # Don't try to enable all hardware (reduces size)
  hardware.enableAllHardware = lib.mkForce false;
  
  # Set a nice ISO label based on hostname
  isoImage.isoName = lib.mkDefault "${config.networking.hostName}-installer.iso";
  
  # Include useful installer tools
  environment.systemPackages = with pkgs; [
    # Partitioning and filesystem tools
    parted
    gptfdisk
    
    # Network tools for the installer
    wget
    curl
    
    # Editors
    vim
    nano
    
    # System info
    lshw
    pciutils
    usbutils
    
    # Useful utilities
    git
    tmux
  ];
  
  # Enable SSH in the installer for remote installation
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };
  
  # Set a default password for the installer (CHANGE THIS!)
  users.users.root.password = "nixos";
  users.users.nixos = {
    isNormalUser = true;
    password = "nixos";
    extraGroups = [ "wheel" ];
  };
  
  # Enable networkmanager for easy network configuration
  networking.networkmanager.enable = lib.mkDefault true;
  
  # Add this repository to the flake registry for easy installation
  nix.registry.dotfiles = {
    from = {
      type = "indirect";
      id = "dotfiles";
    };
    to = {
      type = "github";
      owner = "rengare";
      repo = "dotfiles";
    };
  };
}
