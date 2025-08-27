{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  programs.htop = {
    enable = true;
    package = pkgs.htop;
  };
}
