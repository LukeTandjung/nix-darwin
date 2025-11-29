{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  programs.spicetify = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
  };
}
