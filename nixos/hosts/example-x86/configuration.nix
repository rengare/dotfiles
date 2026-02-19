# Example x86_64 host configuration
# This is a template/example for creating new x86_64 hosts

{ config, lib, pkgs, ... }:

{
  # Import hardware configuration
  # Generate this with: nixos-generate-config --show-hardware-config
  # imports = [ ./hardware-configuration.nix ];

  # Boot loader configuration
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # Example filesystem configuration
  # Adjust based on your actual setup
  fileSystems."/" = {
    device = "/dev/disk/by-label/root";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  # Example swap configuration (optional)
  # swapDevices = [
  #   { device = "/dev/disk/by-label/swap"; }
  # ];

  # Network configuration
  networking = {
    hostName = "example-x86"; # Override if using via flake.nix
    # Uncomment for wireless
    # wireless.enable = true;
  };

  # Example: Using the declarative users module
  imports = [ ../../modules/users.nix ];
  
  myUsers = {
    enable = true;
    users.example = {
      isAdmin = true;
      description = "Example User";
      extraGroups = [ "docker" "libvirtd" ];
      shell = pkgs.fish;
      # sshKeys = [ "ssh-ed25519 AAAA... user@host" ];
    };
  };

  # Or traditional user management:
  # users.users.example = {
  #   isNormalUser = true;
  #   description = "Example User";
  #   extraGroups = [ "wheel" "networkmanager" ];
  # };

  # Host-specific packages
  environment.systemPackages = with pkgs; [
    neovim
    git
    # Add host-specific packages here
  ];

  # Example services
  # services.openssh.enable = true;
  # services.printing.enable = true;
  # virtualisation.docker.enable = true;

  # Desktop environment (if needed)
  # services.xserver = {
  #   enable = true;
  #   displayManager.gdm.enable = true;
  #   desktopManager.gnome.enable = true;
  # };

  # Or window manager
  # programs.sway.enable = true;

  # Override timezone from common.nix if needed
  # time.timeZone = "America/New_York";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of your first install.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  # system.stateVersion = "24.11"; # Already set in common.nix
}
