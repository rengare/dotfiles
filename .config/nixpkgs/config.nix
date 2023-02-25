{ config, pkgs, ... }:

{
  allowUnfree = true;
  allowUnfreePredicate = x: true;
  permittedInsecurePackages = [ "python-2.7.18.6" ];
}
