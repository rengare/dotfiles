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

  wezterm = linkAppConfig "wezterm";
  kitty = linkAppConfig "kitty";
  gitui = linkAppConfig "gitui";
  fish = linkAppConfig "fish";
  lvim = linkAppConfig "lvim";
  nixpkgs = linkAppConfig "nixpkgs";
  scripts = linkAppConfig "scripts";

in
{

  nixpkgs = {
    config = {
      allowUnfree = config.allowUnfree or false;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = config.allowUnfreePredicate or (x: false);
    };
  };

  home.stateVersion = specialArgs.version;
  home.username = pkgs.config.username;
  home.homeDirectory = pkgs.config.home;

  imports = [
    wezterm
    kitty
    gitui
    fish
    lvim
    nixpkgs
    scripts
  ];

  home.packages = [
    pkgs.nixfmt
    pkgs.ripgrep
    pkgs.fd
    pkgs.gitui
    pkgs.fzf
    pkgs.glibcLocales
    pkgs.youtube-dl
    pkgs.rustup
    pkgs.fnm
  ];

  programs.home-manager.enable = true;
}
