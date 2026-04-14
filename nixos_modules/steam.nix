{ config, lib, ... }:
lib.mkIf (config.networking.hostName == "Lukes-Um790") {
  programs.steam.enable = true;
}
