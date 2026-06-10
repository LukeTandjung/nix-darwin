{ pkgs, ... }:
{
  programs.vesktop = {
    enable = true;
    package = pkgs.vesktop;
  };
}
