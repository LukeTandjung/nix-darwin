{ pkgs, lib, config, ... }:
lib.mkIf (config.networking.hostName == "Lukes-Mac-mini") {
  environment.systemPackages = with pkgs; [
    notion-app
  ];
}
