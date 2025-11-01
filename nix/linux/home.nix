{ config, pkgs, specialArgs, lib, ... }:
{
  nixpkgs = {
    config = {
      allowUnfree = specialArgs.allowUnfree or false;
      allowUnfreePredicate = specialArgs.allowUnfreePredicate or (x: false);
    };
  };

  home.stateVersion = specialArgs.version;
  home.username = specialArgs.username;
  home.homeDirectory = specialArgs.home;

  home.packages = [ ];

  programs.home-manager.enable = true;

  imports = [
    ../shared.nix
   ../dev.nix
    ./link.nix
   ./dev.nix
   ./programs.nix
  ];
}
