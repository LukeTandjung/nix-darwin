flake@{ inputs, ... }:
let
  configure = username: { config, lib, pkgs, ... }:
    let
      user = config.hjem.users.${username};
      native = pkgs.callPackage (inputs.hjem + "/cli/package.nix") { };
      activate = pkgs.writeShellApplication {
        name = "hjem";
        text = ''
          # Keep native CLI behaviour except for the deployment entry point.
          case " $* " in
            *" --help "*|*" -h "*|*" --dry-run "*) exec ${lib.getExe native} "$@" ;;
          esac
          if [[ "''${1:-}" == internal && "''${2:-}" == activate ]]; then
            if [[ "$HOME" != ${lib.escapeShellArg user.directory} ]]; then
              echo "Run Hjem activation as ${username}, not a different user." >&2
              exit 1
            fi
            ${lib.getExe native} "$@"
            ${lib.optionalString pkgs.stdenv.hostPlatform.isDarwin (
              user.activationScripts
              |> lib.mapAttrsToList (name: script: "${pkgs.writeShellScript "hjem-${name}" script}")
              |> lib.concatStringsSep "\n"
            )}
          else
            exec ${lib.getExe native} "$@"
          fi
        '';
      };
    in {
      # Keep app-only packages in the user profile so Hjem's app linker can find them.
      environment.pathsToLink = lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ "/Applications" ];

      hjem = {
        users.${username}.imports = [ flake.config.modules.hjem.default ];
        specialArgs.theme = flake.config.styling.forPkgs pkgs;
      } // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
        # Run application setup after native linking rather than racing launchd.
        cli.package = pkgs.symlinkJoin {
          name = "hjem-with-app-setup";
          paths = [ native ];
          postBuild = ''
            rm "$out/bin/hjem"
            ln -s ${activate}/bin/hjem "$out/bin/hjem"
          '';
          inherit (native) meta;
        };
      };
    };
in {
  modules.nixos.hjem = configure "luke";
  modules.darwin.hjem = configure "luketandjung";
}
