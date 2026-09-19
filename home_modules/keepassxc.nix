{ config, lib, pkgs, ... }:
{
  config = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    programs.keepassxc.enable = true;
    # Keep settings writable for database and Secret Service setup in the GUI.
    systemd.user.services.keepassxc = {
      Unit = {
        Description = "KeePassXC password manager";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${config.programs.keepassxc.package}/bin/keepassxc";
        Restart = "on-failure";
        RestartSec = 3;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
