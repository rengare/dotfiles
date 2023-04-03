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

  home.packages = [
    pkgs.chromium
    pkgs.firefox
    pkgs.authy
    pkgs.etcher
    pkgs.onlyoffice-bin
    pkgs.inkscape

    (helpers.nixGLMesaWrap pkgs.obs-studio)
    (helpers.nixGLMesaWrap pkgs.nextcloud-client)
    (helpers.nixGLMesaWrap pkgs.wezterm)
    # (helpers.nixGLMesaWrap pkgs.brave)
    (helpers.nixGLVulkanWrap pkgs.gimp)
    (helpers.nixGLVulkanMesaWrap pkgs.libsForQt5.kdenlive)

  ];

  programs.home-manager.enable = true;
}
