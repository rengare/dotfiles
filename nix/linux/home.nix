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

  imports = [
    (helpers.linkAppConfig "dunst")
    (helpers.linkAppConfig "gtk-3.0")
    (helpers.linkAppConfig "gtk-4.0")
    (helpers.linkAppConfig "i3")
    (helpers.linkAppConfig "hypr")
    (helpers.linkAppConfig "picom")
    (helpers.linkAppConfig "polybar")
    (helpers.linkAppConfig "rofi")
    (helpers.linkAppConfig "sway")
    (helpers.linkAppConfig "waybar")
  ];

  home.packages = [
    pkgs.chromium
    pkgs.firefox
    pkgs.authy
    pkgs.libreoffice
    pkgs.tilix
    pkgs.inkscape

    pkgs.podman
    pkgs.docker
    pkgs.distrobox
    pkgs.apx
    pkgs.libstdcxx5
    pkgs.gcc_multi
    pkgs.etcher

    (helpers.nixGLMesaWrap pkgs.obs-studio)
    (helpers.nixGLMesaWrap pkgs.brave)
    (helpers.nixGLMesaWrap pkgs.sway)
    (helpers.nixGLVulkanWrap pkgs.gimp)
  ];

  programs.home-manager.enable = true;
}
