{ config, lib, pkgs, ... }:
lib.mkIf (config.networking.hostName == "Lukes-Um790") {
  environment.systemPackages = with pkgs; [
    linux-wallpaperengine
  ];
}
