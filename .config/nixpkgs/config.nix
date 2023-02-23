{ config, pkgs, ... }:

{
  allowUnfree = true;
  allowUnfreePredicate = x: true;
}
