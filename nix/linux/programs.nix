{ config, pkgs, specialArgs, lib, ... }:
let
  helpers = import ../helpers.nix {
    inherit pkgs;
    inherit lib;
    inherit config;
    inherit specialArgs;
  };

in {
  home.packages = [
    pkgs.pywal
    pkgs.wpgtk
    pkgs.syncthing
    pkgs.xorg.xinput

    pkgs.feh
    pkgs.ncdu
    pkgs.mpd
    pkgs.rmpc
    pkgs.bluetui
    # (helpers.nixGLVulkanMesaWrap pkgs.picom)
    # (helpers.nixGLMesaWrap pkgs.kitty)

    # (helpers.nixGLMesaWrap pkgs.ytfzf)
  ];
}
