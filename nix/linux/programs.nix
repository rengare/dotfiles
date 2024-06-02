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

    pkgs.pywal
    pkgs.wpgtk
    pkgs.syncthing
    pkgs.xorg.xinput

    pkgs.gammastep
    pkgs.autotiling
    pkgs.dmenu-rs
    pkgs.feh
    pkgs.eza
    pkgs.dunst
    pkgs.arandr
    pkgs.mpv
    (helpers.nixGLVulkanMesaWrap pkgs.picom)
    (helpers.nixGLMesaWrap pkgs.kitty)

    (helpers.nixGLMesaWrap pkgs.ytfzf)
    (helpers.nixGLMesaWrap pkgs.alacritty)
  ];
}
