{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  programs.vesktop = {
    enable = true;
    package = pkgs.vesktop;
  };
}
