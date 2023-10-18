{ config, pkgs, specialArgs, lib, ... }:
{
  home.packages = [
    pkgs.git
    pkgs.neovim
    pkgs.zellij
    pkgs.lazygit
  ];
}
