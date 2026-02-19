{ pkgs, lib, ... }:

{
  # Boot loader configuration
  boot.loader.systemd-boot = {
    enable = true;

    # The default EFI partition created by Windows is really small, limit to 2
    # generations to be on the safe side.
    configurationLimit = 2;
  };

  boot.initrd.systemd = {
    enable = true;

    # This is not secure, but it makes diagnosing errors easier.
    emergencyAccess = true;
  };

  # Hardware configuration
  hardware.enableRedistributableFirmware = true;

  # Filesystem configuration
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/root";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-label/SYSTEM_DRV";
      fsType = "vfat";
    };
  };

  # Enable some SysRq keys (80 = sync + process kill)
  # See: https://docs.kernel.org/admin-guide/sysrq.html
  boot.kernel.sysctl."kernel.sysrq" = 80;

  # User configuration
  users.users.ren = {
    isNormalUser = true;
    # SECURITY NOTE: Default password for initial setup only.
    # This matches the upstream x1e-nixos-config example configuration.
    # IMPORTANT: Change this immediately after first login using `passwd`
    # or remove this line and use `initialPassword` or `hashedPassword` instead.
    password = "nixos";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };

  # SECURITY NOTE: Override the default from common.nix for initial setup convenience.
  # This is convenient for initial setup but reduces security.
  # Consider removing this override after initial configuration.
  security.sudo.wheelNeedsPassword = lib.mkForce false;

  # Additional packages specific to this host
  environment.systemPackages = with pkgs; [
    neovim
    git
  ];

  # NetworkManager configuration
  networking.networkmanager = {
    plugins = lib.mkForce [ ];
  };

  # Hardware support
  hardware.bluetooth.enable = true;

  # Desktop environment and applications
  programs.sway.enable = true;
  programs.firefox.enable = true;
  
  # Timezone for this host (override the UTC default from common.nix if needed)
  # time.timeZone = "America/New_York";
}
