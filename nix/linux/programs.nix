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
    pkgs.syncthing
    pkgs.xorg.xinput

    pkgs.gammastep
    pkgs.autotiling
    pkgs.rofi
    pkgs.dmenu-rs
    pkgs.feh
    pkgs.eza
    pkgs.dunst
    # pkgs.polybar
    pkgs.arandr
    pkgs.blueman
    # pkgs.xclip
    # (helpers.nixGLVulkanMesaWrap pkgs.flameshot)
    (helpers.nixGLVulkanMesaWrap pkgs.picom)
    (helpers.nixGLMesaWrap pkgs.kitty)

    # (helpers.nixGLMesaWrap pkgs.obs-studio)
    # (helpers.nixGLMesaWrap pkgs.brave)
    # (helpers.nixGLMesaWrap pkgs.nextcloud-client)
    # (helpers.nixGLVulkanWrap pkgs.gimp)
    # (helpers.nixGLVulkanMesaWrap pkgs.libsForQt5.kdenlive)
  ];
}
