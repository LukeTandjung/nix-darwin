{ ... }:
{
  modules.home.keepassxc =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      programs.keepassxc = {
        enable = true;
        # Home Manager owns application preferences; database contents remain writable.
        settings = {
          SSHAgent.Enabled = true;
          # Preserve the existing Linux GitHub-token bridge through Secret Service.
          FdoSecrets.Enabled = pkgs.stdenv.hostPlatform.isLinux;
          Browser.UpdateBinaryPath = false;
          GUI = {
            MinimizeOnClose = true;
            MinimizeToTray = true;
            ShowTrayIcon = true;
          };
        };
      };

      systemd.user.services.keepassxc = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        Unit = {
          Description = "KeePassXC password manager";
          PartOf = [ "graphical-session.target" ];
          After = [
            "graphical-session.target"
          ]
          ++ lib.optional config.services.ssh-agent.enable "ssh-agent.service";
          Requires = lib.optional config.services.ssh-agent.enable "ssh-agent.service";
        };
        Service = {
          ExecStart = "${config.programs.keepassxc.package}/bin/keepassxc";
          Environment = lib.optional config.services.ssh-agent.enable "SSH_AUTH_SOCK=%t/${config.services.ssh-agent.socket}";
          Restart = "on-failure";
          RestartSec = 3;
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };

      launchd.agents.keepassxc = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        enable = true;
        config = {
          # nixpkgs installs the macOS GUI executable inside the application bundle.
          ProgramArguments = [
            "${config.programs.keepassxc.package}/Applications/KeePassXC.app/Contents/MacOS/KeePassXC"
          ];
          RunAtLoad = true;
          KeepAlive.SuccessfulExit = false;
          ProcessType = "Interactive";
        };
      };
    };
}
