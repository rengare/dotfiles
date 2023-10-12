{ config, pkgs, lib, specialArgs, ... }:
let
  helpers = import ./helpers.nix {
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
    };
  };

  home.stateVersion = specialArgs.version;
  home.username = specialArgs.username;
  home.homeDirectory = specialArgs.home;

  home.packages = [

    #pkgs.vscode
    # pkgs.postman
    #pkgs.jetbrains.webstorm
  ];

  programs.home-manager.enable = true;
}
