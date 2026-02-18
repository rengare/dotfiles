{ pkgs, lib, ... }:

{
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

  hardware.enableRedistributableFirmware = true;

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

  # SECURITY NOTE: This is convenient for initial setup but reduces security.
  # Consider removing this after initial configuration or setting to true.
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    neovim
    git
    htop
    wget
    curl
  ];

  networking.networkmanager = {
    enable = true;
    plugins = lib.mkForce [ ];
  };

  hardware.bluetooth.enable = true;

  programs.sway.enable = true;
  programs.firefox.enable = true;
}
