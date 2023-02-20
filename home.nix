{ config, pkgs, ... }:

  let 

  dotfiles = builtins.fetchGit {
    url = "https://github.com/rengare/dotfiles";
    ref = "main";
  };

  in
{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "ren";
  home.homeDirectory = "/home/ren";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "23.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  home.packages = [
    pkgs.vscode
    pkgs.chromium
    pkgs.firefox
    pkgs.ripgrep
    pkgs.fd
    pkgs.fzf
    pkgs.ytfzf
    pkgs.authy
  ];
}
