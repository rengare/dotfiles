{ config, pkgs, specialArgs, lib, ... }:
let

  helpers = import ../helpers.nix {
    inherit pkgs;
    inherit lib;
    inherit config;
    inherit specialArgs;
  };

in {
  nixpkgs = {
    config = {
      allowUnfree = config.allowUnfree or false;
      allowUnfreePredicate = config.allowUnfreePredicate or (x: false);
      permittedInsecurePackages = [ "electron-12.2.3" ];
    };
  };

  home.stateVersion = specialArgs.version;
  home.username = pkgs.config.username;
  home.homeDirectory = pkgs.config.home;

  home.packages =
    [ pkgs.podman pkgs.docker pkgs.distrobox pkgs.apx pkgs.gcc_multi ];

  programs.home-manager.enable = true;
}