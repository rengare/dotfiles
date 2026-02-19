{ config, lib, pkgs, ... }:

{
  # Common configuration shared across all hosts
  
  # System state version - update carefully
  system.stateVersion = "24.11";
  
  # Timezone and locale
  time.timeZone = lib.mkDefault "UTC";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  
  # Console configuration
  console = {
    font = lib.mkDefault "Lat2-Terminus16";
    keyMap = lib.mkDefault "us";
  };
  
  # Nix settings common to all systems
  nix = {
    settings = {
      # Enable flakes and nix command
      experimental-features = [ "nix-command" "flakes" ];
      
      # Optimize storage
      auto-optimise-store = true;
      
      # Build settings
      max-jobs = lib.mkDefault "auto";
      
      # Trusted users for multi-user nix
      trusted-users = [ "root" "@wheel" ];
    };
    
    # Automatic garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };
  
  # Security defaults
  security = {
    # Don't allow regular users to use sudo without password by default
    sudo.wheelNeedsPassword = lib.mkDefault true;
    
    # Polkit for privilege escalation
    polkit.enable = true;
  };
  
  # Network configuration defaults
  networking = {
    # Enable networkmanager by default
    networkmanager.enable = lib.mkDefault true;
    
    # Firewall defaults
    firewall = {
      enable = lib.mkDefault true;
      allowPing = lib.mkDefault true;
    };
  };
  
  # Common system packages
  environment.systemPackages = with pkgs; [
    # Essential utilities
    vim
    wget
    curl
    htop
    
    # Network tools
    inetutils
    
    # File management
    file
    tree
    
    # System information
    pciutils
    usbutils
  ];
}
