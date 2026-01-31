{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.beekeeper-studio
  ];
}
