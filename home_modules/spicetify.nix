{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: lib.mkIf pkgs.stdenv.isLinux {
  programs.spicetify = {
    enable = true;
  };
}
