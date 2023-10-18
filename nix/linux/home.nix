{ config, pkgs, specialArgs, lib, ... }:
{
  nixpkgs = {
    config = {
      allowUnfree = config.allowUnfree or false;
      allowUnfreePredicate = config.allowUnfreePredicate or (x: false);
      permittedInsecurePackages = [ "electron-12.2.3" ];
    };
  };

  imports = [
    ../shared.nix
    ../dev.nix
    ./link.nix
    ./dev.nix
    ./programs.nix
  ];

  home.stateVersion = specialArgs.version;
  home.username = specialArgs.username;
  home.homeDirectory = specialArgs.home;

  home.packages = [ ];

  programs.home-manager.enable = true;
}
