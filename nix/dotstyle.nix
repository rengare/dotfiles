# The dotstyle TUI (dotfiles/tui) as a home-manager package.
#
# Built from the checkout rather than fetched, because it reads the theme tree
# that lives beside it — pinning a store copy would theme a different tree than
# the one being edited.
{ config, pkgs, lib, specialArgs, ... }:

let
  dotstyle = pkgs.rustPlatform.buildRustPackage {
    pname = "dotstyle";
    version = "0.1.0";

    src = lib.cleanSource ../tui;
    cargoLock.lockFile = ../tui/Cargo.lock;

    # The tests render the real theme tree, which is outside this src root.
    doCheck = false;

    meta = {
      description = "Theme, font, wallpaper and window-manager look for these dotfiles";
      mainProgram = "dotstyle";
    };
  };
in
{
  home.packages = [ dotstyle ];

  # dotstyle resolves the theme tree relative to its own source dir when run
  # via cargo; an installed binary needs to be told where the checkout is.
  home.sessionVariables.DOTSTYLE_ROOT = specialArgs.path_to_dotfiles;
}
