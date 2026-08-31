{ lib, pkgs, ... }:

{
  programs.claude-desktop = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    enable = true;
  };
}
