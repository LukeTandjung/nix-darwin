{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  programs.obsidian = {
    enable = true;
    package = pkgs.obsidian;
  };
}
