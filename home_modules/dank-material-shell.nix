{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: lib.mkIf pkgs.stdenv.isLinux {
  programs.dankMaterialShell = {
    enable = true;
  };
}
