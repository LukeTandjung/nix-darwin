{ lib, pkgs, ... }:
{
  config = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    xdg.autostart.enable = true;
    programs.keepassxc = {
      enable = true;
      autostart = true;
      # Keep settings writable for database and Secret Service setup in the GUI.
    };
  };
}
