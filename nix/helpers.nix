{ pkgs, lib, config, specialArgs, ... }:
let
  linkAppConfig = appConfig: {
    home.file = {
      ".config/${appConfig}" = {
        source = config.lib.file.mkOutOfStoreSymlink
          "${specialArgs.path_to_dotfiles}/.config/${appConfig}";
        recursive = true;
      };
    };
  };

in {
  linkAppConfig = linkAppConfig;
}
