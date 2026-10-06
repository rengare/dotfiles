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
    # SwayFX (sway + blur) as `swayfx`, run under nixGL so it gets nixpkgs'
    # Mesa. Only the wrapper goes on PATH, so apt's /usr/bin/sway and the
    # plain sway session stay as they are. Session: misc/lemurs/swayfx.
    (pkgs.writeShellScriptBin "swayfx" ''
      exec ${lib.getExe pkgs.nixgl.nixGLIntel} ${pkgs.swayfx}/bin/sway "$@"
    '')

    # Sway session tooling used by dotfiles/bin/dot-*.
    pkgs.swayidle          # idle timeline; dot-session starts it
    pkgs.swaylock          # dot-lock, themed from theme/current/swaylock.conf
    pkgs.cliphist          # clipboard history behind dot-clipboard
    pkgs.wtype             # types the pick from dot-emoji into the focused window
    pkgs.wf-recorder       # dot-capture record
    pkgs.zbar              # dot-capture qr
    pkgs.tesseract         # dot-capture text (OCR)

    pkgs.feh
    pkgs.bluetui
    pkgs.wiremix
    pkgs.wayscriber
    pkgs.rofi # launcher used by dot-rofi-toggle
    pkgs.zathura
    (helpers.nixGLVulkanMesaWrap pkgs.imv)
    # (helpers.nixGLMesaWrap pkgs.kitty)

    # (helpers.nixGLMesaWrap pkgs.ytfzf)
  ];
}
