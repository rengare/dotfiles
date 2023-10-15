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
  home.username = specialArgs.username;
  home.homeDirectory = specialArgs.home;

  home.packages = [
    pkgs.tilix
    pkgs.pywal
    pkgs.autotiling
    #(helpers.nixGLVulkanMesaWrap pkgs.jdk17)
  ];

  programs.home-manager.enable = true;
}
