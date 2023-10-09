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
    (helpers.linkAppConfig "i3")
    (helpers.linkAppConfig "hypr")
    (helpers.linkAppConfig "picom")
    (helpers.linkAppConfig "polybar")
    (helpers.linkAppConfig "rofi")
    (helpers.linkAppConfig "sway")
    (helpers.linkAppConfig "waybar")
    (helpers.linkAppConfig "zellij")
  ];

  home.file.".local/bin/sw" = {
    source = config.lib.file.mkOutOfStoreSymlink
      "${specialArgs.path_to_dotfiles}/.config/sway/launch.sh";
  };

  home.file.".local/bin/it" = {
    source = config.lib.file.mkOutOfStoreSymlink
      "${specialArgs.path_to_dotfiles}/.config/i3/runi3.sh";
  };

  home.file.".tmux.conf" = {
    source = config.lib.file.mkOutOfStoreSymlink
      "${specialArgs.path_to_dotfiles}/.tmux.conf";
  };

  home.packages = [ ];

  programs.home-manager.enable = true;
}
