{ config, pkgs, specialArgs, lib, ... }:
let

  helpers = import ../helpers.nix {
    inherit pkgs;
    inherit lib;
    inherit config;
    inherit specialArgs;
  };

in {
  home.file.".config/mimeapps.list" = {
    source = config.lib.file.mkOutOfStoreSymlink
      "${specialArgs.path_to_dotfiles}/.config/mimeapps.list";
  };

  home.file.".ideavimrc" = {
    source = config.lib.file.mkOutOfStoreSymlink
      "${specialArgs.path_to_dotfiles}/.ideavimrc";
  };

  home.activation = {
    linkDunst = helpers.linkAppConfig "dunst";
    linkI3 = helpers.linkAppConfig "i3";
    linkI3blocks = helpers.linkAppConfig "i3blocks";
    linkSway = helpers.linkAppConfig "sway";
    linkPicom = helpers.linkAppConfig "picom";
    linkPolybar = helpers.linkAppConfig "polybar";
    linkRofi = helpers.linkAppConfig "rofi";
    linkWaybar = helpers.linkAppConfig "waybar";
    linkHypr = helpers.linkAppConfig "hypr";
    linkWofi = helpers.linkAppConfig "wofi";
    linkNiri = helpers.linkAppConfig "niri";
    linkNvim = helpers.linkAppConfig "nvim";
    linkZellij = helpers.linkAppConfig "zellij";
    linkWpg = helpers.linkAppConfig "wpg";
    linkAlacritty = helpers.linkAppConfig "alacritty";
    linkCosmic = helpers.linkAppConfig "cosmic";
    linkFoot = helpers.linkAppConfig "foot";
    linkHelix = helpers.linkAppConfig "helix";
    linkMpd = helpers.linkAppConfig "mpd";
    linkRmpc= helpers.linkAppConfig "rmpc";
    linkZathura= helpers.linkAppConfig "zathura";
    linkLazygit= helpers.linkAppConfig "lazygit";

    linkVSCode = lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p "${specialArgs.home}/.config/Code/User"
      rm -f "${specialArgs.home}/.config/Code/User/settings.json"
      rm -f "${specialArgs.home}/.config/Code/User/keybindings.json"
      rm -rf "${specialArgs.home}/.config/Code/User/snippets"
      ln -s "${specialArgs.path_to_dotfiles}/.config/Code/User/settings.json" "${specialArgs.home}/.config/Code/User/settings.json"
      ln -s "${specialArgs.path_to_dotfiles}/.config/Code/User/keybindings.json" "${specialArgs.home}/.config/Code/User/keybindings.json"
      ln -s "${specialArgs.path_to_dotfiles}/.config/Code/User/snippets" "${specialArgs.home}/.config/Code/User/snippets"
    '';

    linkVSCodium = lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p "${specialArgs.home}/.config/VSCodium/User"
      rm -f "${specialArgs.home}/.config/VSCodium/User/settings.json"
      rm -f "${specialArgs.home}/.config/VSCodium/User/keybindings.json"
      rm -rf "${specialArgs.home}/.config/VSCodium/User/snippets"
      ln -s "${specialArgs.path_to_dotfiles}/.config/VSCodium/User/settings.json" "${specialArgs.home}/.config/VSCodium/User/settings.json"
      ln -s "${specialArgs.path_to_dotfiles}/.config/Code/User/keybindings.json" "${specialArgs.home}/.config/VSCodium/User/keybindings.json"
      ln -s "${specialArgs.path_to_dotfiles}/.config/Code/User/snippets" "${specialArgs.home}/.config/VSCodium/User/snippets"
    '';
  };
}
