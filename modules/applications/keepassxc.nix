{ ... }:
{
  modules.hjem.keepassxc = { pkgs, lib, ... }:
    let
      linux = pkgs.stdenv.hostPlatform.isLinux;
      path = if linux then ".config/keepassxc/keepassxc.ini" else "Library/Application Support/KeePassXC/keepassxc.ini";
    in {
      packages = [ pkgs.keepassxc ];
      # Application preferences are managed; the encrypted database stays writable.
      files.${path}.source = (pkgs.formats.ini { }).generate "keepassxc.ini" {
        SSHAgent.Enabled = true;
        FdoSecrets.Enabled = linux;
        Browser.UpdateBinaryPath = false;
        GUI = { MinimizeOnClose = true; MinimizeToTray = true; ShowTrayIcon = true; };
      };
    } // lib.optionalAttrs linux {
      systemd = {
        services.keepassxc = {
          description = "KeePassXC password manager";
          partOf = [ "graphical-session.target" ];
          after = [ "graphical-session.target" "ssh-agent.service" ];
          requires = [ "ssh-agent.service" ];
          wantedBy = [ "graphical-session.target" ];
          serviceConfig = {
            ExecStart = "${pkgs.keepassxc}/bin/keepassxc";
            Environment = "SSH_AUTH_SOCK=%t/ssh-agent";
            Restart = "on-failure";
            RestartSec = 3;
          };
        };
      };
    };

  modules.darwin.keepassxc = { pkgs, ... }: {
    launchd.user.agents.keepassxc.serviceConfig = {
      Label = "org.hjem.keepassxc";
      ProgramArguments = [ "${pkgs.keepassxc}/Applications/KeePassXC.app/Contents/MacOS/KeePassXC" ];
      RunAtLoad = true;
      KeepAlive.SuccessfulExit = false;
      ProcessType = "Interactive";
    };
  };
}
