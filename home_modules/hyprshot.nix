{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
  programs.hyprshot = {
    enable = true;
    package = pkgs.hyprshot;
    saveLocation = "$HOME/Screenshots";
  };
}
