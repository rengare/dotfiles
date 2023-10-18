{ config, pkgs, lib, specialArgs, ... }:
let
  helpers = import ../helpers.nix {
    inherit pkgs;
    inherit lib;
    inherit config;
    inherit specialArgs;
  };

in
{
  home.packages = [
    (helpers.nixGLVulkanMesaWrap pkgs.steam)
    (helpers.nixGLVulkanMesaWrap pkgs.lutris)
    (helpers.nixGLVulkanMesaWrap pkgs.retroarchFull)
    (helpers.nixGLVulkanMesaWrap pkgs.gamescope)
    (pkgs.mangohud)
  ];
}
