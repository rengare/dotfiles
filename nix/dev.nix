{ config, pkgs, lib, specialArgs, ... }: {
  home.packages = [
    # pkgs.vscode
    #pkgs.jetbrains.webstorm
  ];

  programs.home-manager.enable = true;
}
