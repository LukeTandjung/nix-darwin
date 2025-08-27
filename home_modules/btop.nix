{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  programs.btop = {
    enable = true;
    package = pkgs.btop;
  };
}
