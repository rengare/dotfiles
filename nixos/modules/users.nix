# Declarative user management module
# This module provides a convenient way to declare users across hosts
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.myUsers;
in
{
  options.myUsers = {
    enable = mkEnableOption "declarative user management";
    
    users = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          isAdmin = mkOption {
            type = types.bool;
            default = false;
            description = "Whether the user should have admin (wheel) privileges";
          };
          
          description = mkOption {
            type = types.str;
            default = "";
            description = "User description/full name";
          };
          
          extraGroups = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "Additional groups for the user";
          };
          
          shell = mkOption {
            type = types.package;
            default = pkgs.bash;
            description = "User's default shell";
          };
          
          sshKeys = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "SSH public keys for the user";
          };
        };
      });
      default = {};
      description = "Declarative user definitions";
    };
  };
  
  config = mkIf cfg.enable {
    users.users = mapAttrs (name: userCfg: {
      isNormalUser = true;
      description = userCfg.description;
      extraGroups = userCfg.extraGroups ++ (optional userCfg.isAdmin "wheel") ++ [ "networkmanager" ];
      shell = userCfg.shell;
      openssh.authorizedKeys.keys = userCfg.sshKeys;
    }) cfg.users;
  };
}
