{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
lib.mkIf pkgs.stdenv.isLinux {
  programs.hyprshot = {
    enable = true;
    package = pkgs.hyprshot;
    saveLocation = "$HOME/Screenshots";
  };
}
