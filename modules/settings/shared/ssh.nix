{ ... }:
{
  modules.nixos.ssh = {
    programs.ssh.startAgent = false;
    services.gnome.gcr-ssh-agent.enable = false;
  };

  modules.hjem.ssh = { lib, pkgs, ... }: {
    files.".ssh/config".text = ''
      Host *
        IdentityFile none
        IdentitiesOnly no
        AddKeysToAgent no
    '';
    # macOS retains Apple's launchd-managed SSH_AUTH_SOCK.
    zshEnv = lib.mkIf pkgs.stdenv.hostPlatform.isLinux ''
      if [[ -z "$SSH_AUTH_SOCK" || -z "$SSH_CONNECTION" ]]; then
        export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent"
      fi
    '';
  } // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
    systemd = {
      services.ssh-agent = {
        description = "SSH authentication agent";
        wantedBy = [ "default.target" ];
        wants = [ "set-SSH_AUTH_SOCK.service" ];
        serviceConfig = {
          ExecStart = "${pkgs.openssh}/bin/ssh-agent -D -a %t/ssh-agent";
          Restart = "on-failure";
        };
      };
      services.set-SSH_AUTH_SOCK = {
        description = "Export the SSH agent socket to D-Bus and user services";
        wantedBy = [ "default.target" ];
        after = [ "ssh-agent.service" ];
        before = [ "graphical-session-pre.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          Environment = "SSH_AUTH_SOCK=%t/ssh-agent";
          ExecStart = "${pkgs.dbus}/bin/dbus-update-activation-environment --systemd SSH_AUTH_SOCK";
        };
      };
    };
  };
}
