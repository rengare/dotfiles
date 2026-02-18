{ config, pkgs, specialArgs, lib, ... }:
let

  helpers = import ../helpers.nix {
    inherit pkgs;
    inherit lib;
    inherit config;
    inherit specialArgs;
  };

in {
  home.activation = {
    linkDunst = helpers.linkAppConfig "dunst";
    linkI3 = helpers.linkAppConfig "i3";
    linkPicom = helpers.linkAppConfig "picom";
    linkPolybar = helpers.linkAppConfig "polybar";
    linkRofi = helpers.linkAppConfig "rofi";
    linkWaybar = helpers.linkAppConfig "waybar";
    linkHypr = helpers.linkAppConfig "hypr";
    linkWofi = helpers.linkAppConfig "wofi";
    linkNiri = helpers.linkAppConfig "niri";
    linkNvim = helpers.linkAppConfig "nvim";
    linkZellij = helpers.linkAppConfig "zellij";
    linkWpg = helpers.linkAppConfig "wpg";
    linkAlacritty = helpers.linkAppConfig "alacritty";
    linkCosmic = helpers.linkAppConfig "cosmic";
    linkFoot = helpers.linkAppConfig "foot";
    linkHelix = helpers.linkAppConfig "helix";
    linkMpd = helpers.linkAppConfig "mpd";
    linkRmpc= helpers.linkAppConfig "rmpc";
  };
}
