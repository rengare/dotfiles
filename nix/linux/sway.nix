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
    };
  };

  home.stateVersion = specialArgs.version;
  home.username = pkgs.config.username;
  home.homeDirectory = pkgs.config.home;

  imports = [ ];

  home.packages = [
    # (helpers.nixGLMesaWrap pkgs.sway)
    # (helpers.nixGLMesaWrap pkgs.wlsunset)
    # (helpers.nixGLMesaWrap pkgs.wdisplays)
    # (helpers.nixGLMesaWrap pkgs.wl-clipboard)
    # (helpers.nixGLMesaWrap pkgs.dunst)
    # (helpers.nixGLMesaWrap pkgs.rofi)
    # (helpers.nixGLMesaWrap pkgs.waybar)
  ];

  programs.home-manager.enable = true;
}
