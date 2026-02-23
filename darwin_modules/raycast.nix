{ pkgs, lib, config, ... }:
{
  options.modules.raycast.enable = lib.mkEnableOption "raycast";

  config = lib.mkIf config.modules.raycast.enable {
    environment.systemPackages = with pkgs; [
      raycast
    ];
  };
}
