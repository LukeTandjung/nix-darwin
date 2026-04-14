{ pkgs, lib, osConfig, ... }:
lib.mkIf pkgs.stdenv.isLinux {
  programs.mpvpaper = {
    enable = osConfig.networking.hostName == "Lukes-Um790";
  };
}
