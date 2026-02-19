# Overlays module for custom packages and package overrides
# Use this to add custom packages or override existing ones
{ inputs, ... }:

{
  # This module can be imported in hosts that need custom packages
  nixpkgs.overlays = [
    # Example: Override a package
    # (final: prev: {
    #   neovim = prev.neovim.override {
    #     viAlias = true;
    #     vimAlias = true;
    #   };
    # })
    
    # Example: Add a custom package
    # (final: prev: {
    #   my-custom-package = prev.callPackage ./packages/my-custom-package.nix {};
    # })
    
    # Example: Use a package from unstable while rest of system is on stable
    # (final: prev: {
    #   firefox = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.firefox;
    # })
  ];
}
