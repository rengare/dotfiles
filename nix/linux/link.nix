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

  home.file.".local/bin/sw" = {
    source = config.lib.file.mkOutOfStoreSymlink
      "${specialArgs.path_to_dotfiles}/.config/sway/launch.sh";
  };

  home.packages = [];

  programs.home-manager.enable = true;
}