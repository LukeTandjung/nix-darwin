{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  programs.lazygit = {
    enable = true;
    package = pkgs.lazygit;
  }
}
