{ pkgs, lib, config, ... }:
{
  options.modules.slack.enable = lib.mkEnableOption "slack";

  config = lib.mkIf config.modules.slack.enable {
    environment.systemPackages = with pkgs; [
      slack
    ];
  };
}
