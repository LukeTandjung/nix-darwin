{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  programs.zen-browser = {
    enable = true;
    profiles.luke = {
      isDefault = true;
      settings = {
        "zen.welcome-screen.seen" = true;
      };
    };
  };

  stylix.targets.zen-browser.profileNames = [ "luke" ];
}
