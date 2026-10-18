{ inputs, ... }:
{
  modules.hjem.dank-material-shell = { pkgs, lib, osConfig, theme, ... }:
    let
          settings = {
            # The custom theme file is generated from our shared palette.
            fontFamily = "IBM Plex Sans";
            monoFontFamily = "IBM Plex Sans";
            configVersion = 28;
            radiusStrength = 19;
            widgetBackgroundColor = "s";
            barElevationEnabled = false;
            barInsetPaddingShared = 4;
            barInsetPaddingSyncAll = true;
            launcherLogoMode = "os";
            launcherLogoColorOverride = "primary";
            builtInPluginSettings = {
              dms_settings_search.trigger = "?";
              dms_clipboard_search.trigger = "cb";
              dms_power.trigger = "pw";
              dms_qr_generator.trigger = "qrg";
            };
            barConfigs = [
              {
                id = "default";
                name = "Main Bar";
                island = true;
                islandPalette = "dim";
                islandHomeLayout = [
                  {
                    id = "media";
                    enabled = true;
                  }
                  {
                    id = "clock";
                    enabled = true;
                  }
                  {
                    id = "weather";
                    enabled = true;
                  }
                  {
                    id = "notifications";
                    enabled = true;
                  }
                ];
                followInterfaceStyle = true;
                enabled = true;
                position = 0;
                screenPreferences = [ "all" ];
                showOnLastDisplay = true;
                leftWidgets = [
                  "launcherButton"
                  {
                    id = "workspaceSwitcher";
                    showWorkspaceApps = false;
                    showWorkspaceName = false;
                    showWorkspaceIndex = false;
                    workspaceFocusedBorderEnabled = false;
                    workspaceAppIconSizeOffset = 0;
                    showOccupiedWorkspacesOnly = false;
                    enabled = true;
                  }
                  "focusedWindow"
                ];
                centerWidgets = [
                  "music"
                  "clock"
                  "weather"
                ];
                rightWidgets = [
                  "systemTray"
                  "cpuUsage"
                  "mpvpaperWallpaper"
                  "dankKDEConnect"
                  "notificationButton"
                  {
                    id = "battery";
                    enabled = true;
                  }
                  "controlCenterButton"
                  {
                    id = "vpn";
                    enabled = true;
                  }
                ];
                spacing = 4;
                innerPadding = 4;
                bottomGap = 0;
                transparency = 1;
                widgetTransparency = 1;
                squareCorners = false;
                noBackground = false;
                gothCornersEnabled = false;
                gothCornerRadiusOverride = false;
                gothCornerRadiusValue = 12;
                borderEnabled = false;
                borderColor = "surfaceText";
                borderOpacity = 1;
                borderThickness = 1;
                fontScale = 1;
                autoHide = false;
                autoHideDelay = 250;
                openOnOverview = false;
                visible = true;
                popupGapsAuto = true;
                popupGapsManual = 4;
                widgetPadding = 8;
                barInsetPadding = 4;
                maximizeWidgetText = false;
                maximizeWidgetIcons = false;
                shadowIntensity = 0;
                attachToScreenEdge = false;
                islandFloating = false;
                islandAlongOffset = 0;
                widgetStyle = "pills";
                iconScale = 1;
                islandReserveThickness = 40;
                islandCompactThickness = 30;
                islandHomeCompactTight = false;
              }
            ];
          };
          session = {
            configVersion = 6;
            isLightMode = true;
            wallpaperCyclingEnabled = true;
            wallpaperCyclingInterval = 1800;
            nightModeEnabled = true;
            nightModeAutoEnabled = true;
            nightModeStartHour = 21;
            themeModeAutoEnabled = true;
            themeModeStartHour = 22;
            weatherLocation = "London, UK";
            weatherCoordinates = "51.5074,-0.1278";
            # Launcher history is runtime state, not a declarative preference.
          };

      dms = inputs.dankMaterialShell.lib.mkDmsShell pkgs;
      dsearch = inputs.dsearch.packages.${pkgs.stdenv.hostPlatform.system}.default;
      plugins = inputs.dms-plugin-registry.packages.${pkgs.stdenv.hostPlatform.system};
      selectedPlugins = [ "powerUsagePlugin" "dankKDEConnect" ]
        ++ lib.optional (osConfig.networking.hostName == "Lukes-Um790") "mpvpaperWallpaper";
      dmsColors = variant: with variant.colors; {
        name = variant.name; primary = base0D; primaryText = base00; primaryContainer = base0C;
        secondary = base0E; surface = base01; surfaceText = base05; surfaceVariant = base02;
        surfaceVariantText = base04; surfaceTint = base0D; background = base00;
        backgroundText = base05; outline = base03; surfaceContainer = base01;
        surfaceContainerHigh = base02; surfaceContainerHighest = base03; error = base08;
        warning = base0A; info = base0C;
      };
      customTheme = theme.variants
        |> lib.mapAttrs (_: variant: dmsColors variant)
        |> (pkgs.formats.json { }).generate "dms-kanagawa.json";
    in {
      packages = [ dms dsearch pkgs.quickshell pkgs.glib pkgs.networkmanager pkgs.matugen pkgs.cava ];
      xdg.config.files = {
        "DankMaterialShell/settings.json" = {
          clobber = true;
          source = (pkgs.formats.json { }).generate "dms-settings.json" (settings // {
            currentThemeName = "custom";
            customThemeFile = customTheme;
            popupTransparency = 1.0;
            dockTransparency = 1.0;
          });
        };
      } // lib.genAttrs (map (name: "DankMaterialShell/plugins/${name}") selectedPlugins)
        (path: { source = plugins.${lib.last (lib.splitString "/" path)}; });
      xdg.state.files."DankMaterialShell/session.json" = {
        clobber = true;
        source = (pkgs.formats.json { }).generate "dms-session.json" session;
      };
      systemd.services.dsearch = {
        description = "dsearch - Fast filesystem search service";
        wantedBy = [ "default.target" ];
        after = [ "network.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${dsearch}/bin/dsearch serve";
          Restart = "on-failure";
          RestartSec = "5s";
          StandardOutput = "journal";
          StandardError = "journal";
          SyslogIdentifier = "dsearch";
          TimeoutStopSec = "30s";
        };
      };
    };
}
