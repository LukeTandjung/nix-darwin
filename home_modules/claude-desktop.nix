{ lib, pkgs, ... }:

{
  programs.claude-desktop = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
  };
}
