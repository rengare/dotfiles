{ config, pkgs, specialArgs, lib, ... }:
let

  helpers = import ../helpers.nix {
    inherit pkgs;
    inherit lib;
    inherit config;
    inherit specialArgs;
  };

  mimeapps = config.lib.file.mkOutOfStoreSymlink
    "${specialArgs.path_to_dotfiles}/.config/mimeapps.list";

  # Every location an XDG mime resolver consults, all pointing at the single
  # source of truth in .config/mimeapps.list. Desktop-specific lists take
  # precedence over the plain one, so any of them left unmanaged can silently
  # shadow it (cosmic-files and cosmic-settings create such a copy on their own).
  # Every dot-* helper in dotfiles/bin, linked into ~/.local/bin. That directory
  # is already on the PATH sway itself was started with, which is what lets the
  # keybindings call these by bare name.
  dotScripts = builtins.filter (name: builtins.substring 0 4 name == "dot-")
    (builtins.attrNames (builtins.readDir ../../bin));

  mimeappsTargets = [
    ".config/mimeapps.list"
    ".config/sway-mimeapps.list"
    ".config/i3-mimeapps.list"
    ".config/hyprland-mimeapps.list"
    ".config/niri-mimeapps.list"
    ".config/cosmic-mimeapps.list"
    ".local/share/applications/mimeapps.list"
  ];

in {
  home.file = (lib.genAttrs mimeappsTargets (_: { source = mimeapps; }))
    // (lib.listToAttrs (map (name: {
        name = ".local/bin/${name}";
        value = {
          # No `executable = true` here. It makes home-manager copy the file
          # into the nix store to set the mode, which defeats the whole point
          # of an out-of-store symlink and fails outright while bin/ is
          # untracked — a git flake only sees tracked files. The scripts carry
          # their own exec bit, and the symlink points straight at them.
          source = config.lib.file.mkOutOfStoreSymlink
            "${specialArgs.path_to_dotfiles}/bin/${name}";
        };
      }) dotScripts))
    // {
    ".ideavimrc" = {
      source = config.lib.file.mkOutOfStoreSymlink
        "${specialArgs.path_to_dotfiles}/.ideavimrc";
    };
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
      ln -s "${specialArgs.path_to_dotfiles}/.config/Code/User/settings.json" "${specialArgs.home}/.config/VSCodium/User/settings.json"
      ln -s "${specialArgs.path_to_dotfiles}/.config/Code/User/keybindings.json" "${specialArgs.home}/.config/VSCodium/User/keybindings.json"
      ln -s "${specialArgs.path_to_dotfiles}/.config/Code/User/snippets" "${specialArgs.home}/.config/VSCodium/User/snippets"
    '';
  };
}
