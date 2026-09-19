{ config, lib, pkgs, osConfig, ... }:
let
  uid = toString osConfig.users.users.${config.home.username}.uid;
  credential = "/run/user/${uid}/nix-github/token.conf";
  exportToken = pkgs.writeShellApplication {
    name = "nix-github-token";
    runtimeInputs = [ pkgs.libsecret pkgs.coreutils ];
    text = ''
      set +x
      umask 077
      token=$(secret-tool lookup service gh:github.com username LukeTandjung)
      if [[ -z "$token" || "$token" == *$'\n'* || "$token" == *$'\r'* ]]; then
        echo 'KeePassXC did not return a valid GitHub token' >&2
        exit 1
      fi
      tmp=$(mktemp "$RUNTIME_DIRECTORY/.token.XXXXXX")
      trap 'rm -f "$tmp"' EXIT
      printf 'extra-access-tokens = github.com=%s\n' "$token" > "$tmp"
      unset token
      mv "$tmp" "$RUNTIME_DIRECTORY/token.conf"
    '';
  };
in {
  config = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    nix.extraOptions = ''
      !include ${credential}
    '';

    systemd.user.services.nix-github-token = {
      Unit = {
        Description = "Read the Nix GitHub token from KeePassXC Secret Service";
        After = [ "graphical-session.target" "dbus.service" ];
        PartOf = [ "graphical-session.target" ];
        StartLimitIntervalSec = 0;
      };
      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${exportToken}/bin/nix-github-token";
        Environment = "DBUS_SESSION_BUS_ADDRESS=unix:path=%t/bus";
        RuntimeDirectory = "nix-github";
        RuntimeDirectoryMode = "0700";
        UMask = "0077";
        Restart = "on-failure";
        RestartSec = 60;
        TimeoutStartSec = 45;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
