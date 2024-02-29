{ config, pkgs, lib, specialArgs, ... }:

let

  helpers = import ./helpers.nix {
    inherit pkgs;
    inherit lib;
    inherit config;
    inherit specialArgs;
  };

in
{
  home.activation = {
    linkWezterm = helpers.linkAppConfig "wezterm";
    linkKitty = helpers.linkAppConfig "kitty";
    linkNushell = helpers.linkAppConfig "nushell";
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
    pkgs.fzf
    pkgs.jq
    pkgs.unar
    pkgs.zoxide
    pkgs.poppler
    pkgs.ffmpegthumbnailer
    pkgs.gitui
    pkgs.fnm
    pkgs.pyenv
    pkgs.dbeaver
    pkgs.fish
    pkgs.oh-my-fish
    pkgs.eza
    pkgs.gh
    pkgs.delta
    pkgs.htop
    pkgs.llvm
    pkgs.neovim
    pkgs.lunarvim
    pkgs.nushell
    pkgs.lazygit
    pkgs.rustup
    (helpers.nixGLMesaWrap pkgs.alacritty)
    # pkgs.yazi # will be fixed in next stage release
  ];
}
