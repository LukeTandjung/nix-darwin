{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  programs.mise = {
    enable = true;
    enableZshIntegration = true;
  };
}
