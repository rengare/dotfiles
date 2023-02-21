{ config, pkgs, ... }: {

  nixpkgs = {
    config = {
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = (_: true);
    };
  };

  home.stateVersion = "23.05";
  home.username = pkgs.config.username;
  home.homeDirectory = pkgs.config.home;

  home.packages = [ pkgs.nixfmt pkgs.ripgrep pkgs.fd ];

  programs.home-manager.enable = true;
}
