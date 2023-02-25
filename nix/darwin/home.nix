{ config, pkgs, specialArgs, ... }:
let
  linkAppConfig = appConfig: {
    home.file = {
      ".config/${appConfig}" = {
        source = config.lib.file.mkOutOfStoreSymlink
          "${specialArgs.path_to_dotfiles}/.config/${appConfig}";
        recursive = true;
      };
    };
  };

  sketchybar = linkAppConfig "sketchybar";
  skhd = linkAppConfig "skhd";
  yabai = linkAppConfig "yabai";

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

  imports = [ sketchybar skhd yabai ];

  home.packages = [ pkgs.vscode ];

  programs.home-manager.enable = true;
}
