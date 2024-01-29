{ config, pkgs, lib, specialArgs, ... }:

let

  helpers = import ./helpers.nix {
    inherit pkgs;
    inherit lib;
    inherit config;
    inherit specialArgs;
  };

in {
  home.activation  = {
    linkWezterm = helpers.linkAppConfig "wezterm";
    linkKitty = helpers.linkAppConfig "kitty";
    linkGitui = helpers.linkAppConfig "gitui";
    linkFish = helpers.linkAppConfig "fish";
    linkLvim = helpers.linkAppConfig "lvim";
    linkNixpkgs = helpers.linkAppConfig "nixpkgs";
    linkScripts = helpers.linkAppConfig "scripts";
  };

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
    pkgs.eza
    pkgs.jq
    pkgs.gh
    pkgs.delta
    # pkgs.neovim
    pkgs.htop
    pkgs.llvm
  ];
}
