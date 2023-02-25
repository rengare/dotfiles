{ config, pkgs, specialArgs, lib, ... }:
let

  helpers = import ../helpers.nix {
    inherit pkgs;
    inherit lib;
  };

  linkAppConfig = appConfig: {
    home.file = {
      ".config/${appConfig}" = {
        source = config.lib.file.mkOutOfStoreSymlink
          "${specialArgs.path_to_dotfiles}/.config/${appConfig}";
        recursive = true;
      };
    };
  };

  dunst = linkAppConfig "dunst";
  gtk_3_0 = linkAppConfig "gtk-3.0";
  gtk_4_0 = linkAppConfig "gtk-4.0";
  i3 = linkAppConfig "i3";
  hypr = linkAppConfig "hypr";
  picom = linkAppConfig "picom";
  polybar = linkAppConfig "polybar";
  rofi = linkAppConfig "rofi";
  sway = linkAppConfig "sway";
  waybar = linkAppConfig "waybar";

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

  imports = [ dunst gtk_3_0 gtk_4_0 i3 hypr picom polybar rofi sway waybar ];

  home.packages = [
    pkgs.vscode
    pkgs.chromium
    pkgs.firefox
    pkgs.authy
    pkgs.libreoffice
    (helpers.nixGLMesaWrap pkgs.obs-studio)
    (helpers.nixGLMesaWrap pkgs.brave)
    (helpers.nixGLVulkanWrap pkgs.gimp)
  ];

  programs.home-manager.enable = true;
}
