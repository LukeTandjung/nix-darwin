{ config, lib, ... }:
lib.mkIf (config.networking.hostName == "Lukes-Um790") {
  services.ratbagd.enable = true;
}
