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
    pkgs.syncthing

    pkgs.feh
    pkgs.ncdu
    pkgs.mpd
    pkgs.rmpc
    pkgs.bluetui
    pkgs.wiremix
    pkgs.wayscriber
    pkgs.zathura
    pkgs.snitch
    pkgs.zola
    pkgs.youtube-tui
    (helpers.nixGLVulkanMesaWrap pkgs.imv)
    # (helpers.nixGLMesaWrap pkgs.kitty)

    # (helpers.nixGLMesaWrap pkgs.ytfzf)
  ];
}
