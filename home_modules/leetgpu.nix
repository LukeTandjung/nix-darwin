{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  programs.leetgpu = {
    enable = true;
  };
}
