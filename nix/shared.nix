{ config, pkgs, lib, specialArgs, ... }:

let

  helpers = import ./helpers.nix {
    inherit pkgs;
    inherit lib;
    inherit config;
    inherit specialArgs;
  };

  wezterm = helpers.linkAppConfig "wezterm";
  kitty = helpers.linkAppConfig "kitty";
  gitui = helpers.linkAppConfig "gitui";
  fish = helpers.linkAppConfig "fish";
  lvim = helpers.linkAppConfig "lvim";
  nixpkgs = helpers.linkAppConfig "nixpkgs";
  scripts = helpers.linkAppConfig "scripts";

in {

  nixpkgs = {
    config = {
      allowUnfree = config.allowUnfree or false;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = config.allowUnfreePredicate or (x: false);
    };
  };

  home.stateVersion = specialArgs.version;
  home.username = specialArgs.username;
  home.homeDirectory = specialArgs.home;

  imports = [ wezterm kitty gitui fish lvim nixpkgs scripts ];

  home.file.".bash_profile" = {
    source = config.lib.file.mkOutOfStoreSymlink
      "${specialArgs.path_to_dotfiles}/.bash_profile";
  };

  home.file.".bashrc" = {
    source = config.lib.file.mkOutOfStoreSymlink
      "${specialArgs.path_to_dotfiles}/.bashrc";
  };

  home.file.".gitconfig" = {
    source = config.lib.file.mkOutOfStoreSymlink
      "${specialArgs.path_to_dotfiles}/.gitconfig";
  };

  home.file.".zshrc" = {
    source = config.lib.file.mkOutOfStoreSymlink
      "${specialArgs.path_to_dotfiles}/.zshrc";
  };

  home.packages = [
    pkgs.nixfmt
    pkgs.ripgrep
    pkgs.fd
    pkgs.gitui
    pkgs.fzf
    pkgs.fnm
    pkgs.dbeaver
    pkgs.fish
    pkgs.oh-my-fish
    pkgs.broot
    pkgs.exa
    pkgs.jq
    pkgs.gh
    pkgs.delta
    # pkgs.neovim
    pkgs.htop
    pkgs.llvm
  ];

  home.sessionPath = [ "$HOME/.local/bin" ];

  programs.home-manager.enable = true;
}
