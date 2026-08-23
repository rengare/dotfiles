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

    # cosmic-theme derives COSMIC's on-disk theme, and it is not published to
    # crates.io — so it, and the four other git sources it drags in behind it,
    # are fetched from git.
    #
    # `allowBuiltinFetchGit` rather than the usual `outputHashes`, because
    # libcosmic vendors iced as a git *submodule* and cosmic-config depends on
    # it by path. importCargoLock's hash-pinned path calls `fetchgit` without
    # `fetchSubmodules`, so the fetch succeeds, the tree arrives without
    # `iced/`, and the vendor step fails with "Cannot find path for crate
    # 'iced_core'". The builtin fetcher passes `submodules = true`.
    #
    # It stays reproducible — every revision is pinned in Cargo.lock — but it
    # is fetched at evaluation time rather than as a fixed-output derivation,
    # so the first build after a `rm -rf ~/.cache/nix` re-clones libcosmic.
    cargoLock = {
      lockFile = ../tui/Cargo.lock;
      allowBuiltinFetchGit = true;
    };

    # The tests render the real theme tree, which is outside this src root.
    doCheck = false;

    # libcosmic vendors an iced whose `build_helpers` declares
    # `rust-version = "1.92"`, and this nixpkgs ships 1.91.1 — so cargo refuses
    # before compiling anything. The declaration is the crate's own floor, not
    # something the build actually needs: it compiles clean on 1.91.1.
    #
    # Drop this once nixpkgs catches up. If a future libcosmic really does need
    # newer rustc, the failure will be a compile error rather than this one.
    cargoBuildFlags = [ "--ignore-rust-version" ];

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
