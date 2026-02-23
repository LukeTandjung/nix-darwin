{ pkgs, lib, config, ... }:
{
  options.modules.notion.enable = lib.mkEnableOption "notion";

  config = lib.mkIf config.modules.notion.enable {
    environment.systemPackages = with pkgs; [
      notion-app
    ];
  };
}
