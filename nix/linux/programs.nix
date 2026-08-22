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

    # Sway session tooling used by dotfiles/bin/dot-*.
    pkgs.swayidle          # idle timeline; dot-session starts it
    pkgs.swaylock          # dot-lock, themed from theme/current/swaylock.conf
    pkgs.cliphist          # clipboard history behind dot-clipboard
    pkgs.wtype             # types the pick from dot-emoji into the focused window
    pkgs.wf-recorder       # dot-capture record
    pkgs.zbar              # dot-capture qr
    pkgs.tesseract         # dot-capture text (OCR)
    pkgs.terminaltexteffects # dot-screensaver
    pkgs.chafa             # dot-transcode ascii

    pkgs.feh
    pkgs.ncdu # folder file size
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
