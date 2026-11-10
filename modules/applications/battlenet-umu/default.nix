{ ... }:
{
  # Hjem port of https://github.com/jacobjdowning/battlenet-umu.
  modules.hjem.battlenet-umu-implementation =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.battlenet-umu;
      json = pkgs.formats.json { };
      instawow = pkgs.instawow.override {
        python3 = pkgs.python3.override {
          packageOverrides = _: previous: {
            aiohttp-client-cache = previous.aiohttp-client-cache.overridePythonAttrs (old: {
              # Upstream test fixes for aiohttp 3.14 and pytest 9.1.
              patches = (old.patches or [ ]) ++ [
                (pkgs.fetchpatch {
                  url = "https://github.com/requests-cache/aiohttp-client-cache/commit/6fdc8b3f4ed318f0a0b42f8906884b99e7a70d38.patch";
                  hash = "sha256-7eKT1hyGh5lExHWqyZmkFz9swmC6kFCdTYCZPFGhM44=";
                })
                (pkgs.fetchpatch {
                  url = "https://github.com/requests-cache/aiohttp-client-cache/commit/db7910effe01650a0ca16af0f528ca01445bebcf.patch";
                  hash = "sha256-3E9Wmqo4EbfzC46zjyUecmNW1wsPoRp6XZc2RxSnAkA=";
                })
              ];
            });
          };
        };
      };

      gameType = lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "Name of the installed game.";
          };
          path = lib.mkOption {
            type = lib.types.str;
            default = "Program Files (x86)/Battle.net/Battle.net Launcher.exe";
            description = "Path to the executable within the prefix's C:/ drive.";
          };
          proton = lib.mkOption {
            type = lib.types.package;
            default = pkgs.proton-ge-bin;
            description = "Proton package used for the game.";
          };
          launchArgs = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Launch options passed to the executable.";
          };
        };
      };

      profileType = lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.strMatching "[A-Za-z0-9_]+";
            description = "Name of the instawow profile for this version.";
          };
          addonDir = lib.mkOption {
            type = lib.types.str;
            description = "Path to the Addons folder within the prefix's C:/ drive.";
          };
          flavour = lib.mkOption {
            type = lib.types.enum [
              "mainline"
              "vanilla_classic"
              "forever_classic"
              "tbc_classic"
              "wrath_classic"
              "titan_classic"
              "cata_classic"
              "mists_classic"
            ];
            description = "World of Warcraft version used by these addons.";
          };
          addons = lib.mkOption {
            type = lib.types.listOf (lib.types.strMatching "(github|curse|tukui|wago|wowi):[^[:space:]]+");
            default = [ ];
            example = [ "github:sfx-wow/masque" ];
            description = "Addons to install for this version.";
          };
          extraConfig = lib.mkOption {
            type = json.type;
            default = { };
            description = "Extra instawow profile configuration.";
          };
        };
      };

      gamePackage =
        game:
        let
          lowerName = lib.toLower game.name;
          nameParts = builtins.filter builtins.isString (builtins.split "[^a-z]+" lowerName);
          scriptName = lib.concatStringsSep "-" (nameParts ++ [ "umu" ]);
          script = pkgs.writeShellApplication {
            name = scriptName;
            runtimeInputs = [
              pkgs.umu-launcher
              pkgs.curl
              pkgs.coreutils
              pkgs.xdg-terminal-exec
            ];
            runtimeEnv = {
              GAMEID = "umu-default";
              PROTONPATH = "${game.proton.steamcompattool}";
              BNET_PREFIX = cfg.prefix;
              BNET_PATH = "Program Files (x86)/Battle.net/Battle.net Launcher.exe";
              WIN_PATH = game.path;
              LAUNCH_ARGS = game.launchArgs;
            }
            // lib.optionalAttrs (cfg.updateRuntime != null) {
              UMU_RUNTIME_UPDATE = if cfg.updateRuntime then 1 else 0;
            };
            text = builtins.readFile ./bnet-umu.sh;
          };
          desktopItem = pkgs.makeDesktopItem {
            name = scriptName;
            desktopName = game.name;
            exec = lib.getExe script;
            terminal = false;
            categories = [ "Game" ];
          };
        in
        pkgs.symlinkJoin {
          name = scriptName;
          paths = [
            script
            desktopItem
          ];
          meta.mainProgram = scriptName;
        };

      syncPackage = pkgs.writeShellApplication {
        name = "sync-addons";
        runtimeInputs = [
          cfg.addons.package
          pkgs.coreutils
          pkgs.gnugrep
        ];
        runtimeEnv =
          builtins.listToAttrs (
            lib.concatMap (
              profile:
              let
                name = lib.toUpper profile.name;
              in
              [
                {
                  name = "${name}_ADDONS";
                  value = lib.concatStringsSep "\n" profile.addons;
                }
                {
                  name = "${name}_ADDON_DIR";
                  value = profile.addonDir;
                }
              ]
            ) cfg.addons.versions
          )
          // {
            BNET_PREFIX = cfg.prefix;
          };
        text = builtins.readFile ./sync-addons.sh;
      };

      profileFiles = builtins.listToAttrs (
        map (profile: {
          name = "instawow/profiles/${profile.name}/config.json";
          value.source = json.generate "${profile.name}-config.json" (
            {
              profile = profile.name;
              addon_dir = lib.concatStringsSep "/" [
                cfg.prefix
                "drive_c"
                profile.addonDir
              ];
              flavour_override = profile.flavour;
            }
            // profile.extraConfig
          );
        }) cfg.addons.versions
      );

      hasMainConfig =
        cfg.addons.tokens.cfcore != null
        || cfg.addons.tokens.github != null
        || cfg.addons.tokens.wagoAddons != null
        || cfg.addons.extraConfig != { };

      mainConfig = json.generate "instawow-config.json" (
        {
          access_tokens = {
            inherit (cfg.addons.tokens) cfcore github;
            wago_addons = cfg.addons.tokens.wagoAddons;
          };
        }
        // cfg.addons.extraConfig
      );
    in
    {
      options.programs.battlenet-umu = {
        enable = lib.mkEnableOption "umu-launcher for Battle.net games";
        prefix = lib.mkOption {
          type = lib.types.path;
          default = "${config.xdg.data.directory}/battlenet-umu/prefix";
          description = "Wine prefix shared by Battle.net and its games.";
        };
        updateRuntime = lib.mkOption {
          type = lib.types.nullOr lib.types.bool;
          default = null;
          description = "Whether umu checks for a runtime update on every launch; null checks only when no runtime is installed.";
        };
        games = lib.mkOption {
          type = lib.types.listOf gameType;
          default = [ { name = "Battle.net"; } ];
          description = "Battle.net game definitions.";
        };
        addons = {
          enable = lib.mkEnableOption "addon management through instawow";
          package = lib.mkOption {
            type = lib.types.package;
            default = instawow;
            description = "Instawow package used to sync addons.";
          };
          tokens = lib.mkOption {
            type = lib.types.submodule {
              options = {
                cfcore = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                };
                github = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                };
                wagoAddons = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                };
              };
            };
            default = { };
            description = "API tokens for addon providers. Tokens are stored unencrypted in the world-readable Nix store.";
          };
          versions = lib.mkOption {
            type = lib.types.listOf profileType;
            default = [ ];
            description = "World of Warcraft versions with declaratively managed addons.";
          };
          extraConfig = lib.mkOption {
            type = json.type;
            default = { };
            description = "Extra top-level instawow configuration.";
          };
        };
      };

      config = lib.mkMerge [
        (lib.mkIf cfg.enable {
          packages = map gamePackage cfg.games;
        })
        (lib.mkIf cfg.addons.enable {
          packages = [
            syncPackage
            cfg.addons.package
          ];
          xdg.config.files =
            profileFiles
            // lib.optionalAttrs hasMainConfig {
              "instawow/config.json".source = mainConfig;
            };
          systemd.services.wow-addon-sync = lib.mkIf (cfg.addons.versions != [ ]) {
            description = "Sync WoW addons to their declared configuration";
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];
            wantedBy = [ "default.target" ];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = map (profile: "${lib.getExe syncPackage} ${profile.name}") cfg.addons.versions;
            };
          };
        })
      ];
    };

  modules.hjem.battlenet-umu =
    { lib, pkgs, ... }:
    {
      programs.battlenet-umu = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        enable = true;
        games = [
          { name = "Battle.net"; }
          {
            name = "WoW: Forever";
            path = "Program Files (x86)/World of Warcraft/_forever_/Wow.exe";
          }
        ];
      };
    };
}
