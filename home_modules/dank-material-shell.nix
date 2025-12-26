{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: lib.mkIf pkgs.stdenv.isLinux {
  programs.dank-material-shell = {
    enable = true;
    enableCalendarEvents = false;
  };
}
