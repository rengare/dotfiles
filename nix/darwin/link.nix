{ config, pkgs, specialArgs, lib, ... }:
let

  helpers = import ../helpers.nix {
    inherit pkgs;
    inherit lib;
    inherit config;
    inherit specialArgs;
  };

  # VS Code on macOS reads its settings from Application Support, not ~/.config
  codeUser = "${specialArgs.home}/Library/Application Support/Code/User";

in {
  home.file.".ideavimrc" = {
    source = config.lib.file.mkOutOfStoreSymlink
      "${specialArgs.path_to_dotfiles}/.ideavimrc";
  };

  home.activation = {
    linkNvim = helpers.linkAppConfig "nvim";
    linkHelix = helpers.linkAppConfig "helix";
    linkLazygit = helpers.linkAppConfig "lazygit";
    linkZellij = helpers.linkAppConfig "zellij";
    linkAlacritty = helpers.linkAppConfig "alacritty";
    linkStarship = helpers.linkAppConfig "starship.toml";
    linkMpd = helpers.linkAppConfig "mpd";
    linkRmpc = helpers.linkAppConfig "rmpc";
    linkYabai = helpers.linkAppConfig "yabai";
    linkSkhd = helpers.linkAppConfig "skhd";
    linkSketchybar = helpers.linkAppConfig "sketchybar";
    linkAerospace = helpers.linkAppConfig "aerospace";

    linkVSCode = lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p "${codeUser}"
      rm -f "${codeUser}/settings.json"
      rm -f "${codeUser}/keybindings.json"
      rm -rf "${codeUser}/snippets"
      ln -s "${specialArgs.path_to_dotfiles}/.config/Code/User/settings.json" "${codeUser}/settings.json"
      ln -s "${specialArgs.path_to_dotfiles}/.config/Code/User/keybindings.json" "${codeUser}/keybindings.json"
      ln -s "${specialArgs.path_to_dotfiles}/.config/Code/User/snippets" "${codeUser}/snippets"
    '';
  };
}
