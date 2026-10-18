{ ... }:
{
  modules.nixos.git = { config, lib, ... }: {
    # Match the per-user runtime token exported below, including root Nix builds.
    users.users.luke.uid = lib.mkDefault 1000;
    nix.extraOptions = ''
      !include /run/user/${toString config.users.users.luke.uid}/nix-github/token.conf
    '';
  };

  modules.hjem.git = { config, lib, pkgs, osConfig, ... }:
    let
      uid = toString osConfig.users.users.${config.user}.uid;
      credential = "/run/user/${uid}/nix-github/token.conf";
      exportToken = pkgs.writeShellApplication {
        name = "nix-github-token";
        runtimeInputs = [
          pkgs.libsecret
          pkgs.coreutils
        ];
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
    in
    lib.mkMerge [
      {
        packages = [ pkgs.git pkgs.git-lfs pkgs.gh ];
        xdg.config.files."gh/config.yml".text = ''
          version: "1"
          git_protocol: ssh
        '';
        xdg.config.files."git/config".text = lib.generators.toGitINI {
          user = { name = "LukeTandjung"; email = "lukelucus123@gmail.com"; };
          credential."https://github.com".helper = "${pkgs.gh}/bin/gh auth git-credential";
          credential."https://gist.github.com".helper = "${pkgs.gh}/bin/gh auth git-credential";
          filter.lfs = {
            clean = "${pkgs.git-lfs}/bin/git-lfs clean -- %f";
            smudge = "${pkgs.git-lfs}/bin/git-lfs smudge -- %f";
            process = "${pkgs.git-lfs}/bin/git-lfs filter-process";
            required = true;
          };
        };
      }
      (lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        # Account metadata only. gh reads the token from KeePassXC Secret Service
        # using service=gh:github.com and username=LukeTandjung.
        xdg.config.files."gh/hosts.yml" = {
          clobber = true;
          text = ''
            github.com:
              git_protocol: ssh
              user: LukeTandjung
              users:
                LukeTandjung: {}
          '';
        };
        xdg.config.files."nix/nix.conf".text = ''
          !include ${credential}
        '';
        systemd.services.nix-github-token = {
          description = "Read the Nix GitHub token from KeePassXC Secret Service";
          after = [ "graphical-session.target" "dbus.service" ];
          partOf = [ "graphical-session.target" ];
          unitConfig.StartLimitIntervalSec = 0;
          wantedBy = [ "graphical-session.target" ];
          serviceConfig = {
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
        };
      })
    ];
}
