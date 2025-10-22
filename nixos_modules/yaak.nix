{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    yaak
  ];
}
