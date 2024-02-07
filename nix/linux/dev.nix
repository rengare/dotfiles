{ config, pkgs, specialArgs, lib, ... }:
{
  home.packages = [
    pkgs.git
    pkgs.zellij
    pkgs.lazygit
    pkgs.libgcc
  ];
}
