{ pkgs, lib, osConfig, ... }:
lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
  programs.mpvpaper = {
    enable = osConfig.networking.hostName == "Lukes-Um790";
  };
}
