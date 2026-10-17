{ ... }:
{
  modules.hjem.home-base = { config, lib, pkgs, ... }: {
    options = {
      zshEnv = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "Environment setup for every Zsh invocation.";
      };
      zshInit = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "Interactive Zsh integration contributed by enabled applications.";
      };
      activationScripts = lib.mkOption {
        type = lib.types.attrsOf lib.types.lines;
        default = { };
        description = "Per-user application setup, run by native user services after file deployment.";
      };
    };
    config = {
      files.".hushlogin".text = "";
      environment.sessionVariables = {
        EDITOR = "hx";
      } // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        LOCALE_ARCHIVE_2_27 = "${pkgs.glibcLocales}/lib/locale/locale-archive";
      } // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
        DOCKER_HOST = "unix://${config.directory}/.orbstack/run/docker.sock";
        TERMINFO_DIRS = "/etc/profiles/per-user/${config.user}/share/terminfo:$TERMINFO_DIRS\${TERMINFO_DIRS:+:}/usr/share/terminfo";
      };
    } // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
      xdg.config.files."environment.d/10-hjem.conf".text = config.environment.sessionVariables
        |> lib.mapAttrsToList (name: value: "${name}=${toString value}")
        |> lib.concatStringsSep "\n";
      systemd = {
        services = lib.mapAttrs' (name: script:
          lib.nameValuePair "hjem-${name}" {
            description = "Set up ${name} user configuration";
            wantedBy = [ "default.target" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = "${pkgs.writeShellScript "hjem-${name}" script}";
            };
          }
        ) config.activationScripts;
      };
    };
  };
}
