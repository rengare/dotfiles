{ config, pkgs, specialArgs, lib, ... }:
let

  helpers = import ../helpers.nix {
    inherit pkgs;
    inherit lib;
    inherit config;
    inherit specialArgs;
  };

in
{
  home.packages = [
    pkgs.chromium
    pkgs.firefox
    pkgs.etcher
    pkgs.onlyoffice-bin
    pkgs.inkscape
    pkgs.gimp
    pkgs.tilix

    pkgs.pywal
    pkgs.wpgtk
    pkgs.autotiling
    pkgs.syncthing
    pkgs.xorg.xinput
    pkgs.eww
    # (helpers.nixGLMesaWrap pkgs.obs-studio)
    # (helpers.nixGLMesaWrap pkgs.wezterm)
    # (helpers.nixGLMesaWrap pkgs.brave)
    # (helpers.nixGLMesaWrap pkgs.nextcloud-client)
    # (helpers.nixGLVulkanWrap pkgs.gimp)
    # (helpers.nixGLVulkanMesaWrap pkgs.libsForQt5.kdenlive)
  ];
}
