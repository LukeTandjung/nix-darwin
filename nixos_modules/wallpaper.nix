{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  # We first need to install Steam, download Wallpaper Engine, then install linux-wallpaper engine!
  programs.steam = {
    enable = true;
  };

  environment.systemPackages = with pkgs; [
    linux-wallpaperengine
  ];
}
