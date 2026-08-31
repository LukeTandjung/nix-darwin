{ config, lib, pkgs, ... }:
lib.mkIf (config.networking.hostName == "Lukes-Um790") {
  hardware.logitech.wireless.enable = true;
  programs.solaar.enable = true;
}
