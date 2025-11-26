{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  programs.rclone = {
    enable = true;
  };
}
