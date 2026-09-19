{ pkgs, lib, osConfig, ... }:
lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
  programs = {
    dsearch.enable = true;

    dank-material-shell = {
      enable = true;
      enableCalendarEvents = false;
      settings = {
        # The custom theme file is supplied by Stylix.
        fontFamily = lib.mkForce "IBM Plex Sans";
        monoFontFamily = lib.mkForce "IBM Plex Sans";
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
              { id = "media"; enabled = true; }
              { id = "clock"; enabled = true; }
              { id = "weather"; enabled = true; }
              { id = "notifications"; enabled = true; }
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
              { id = "battery"; enabled = true; }
              "controlCenterButton"
              { id = "vpn"; enabled = true; }
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
      plugins.powerUsagePlugin.enable = true;
      plugins.dankKDEConnect.enable = true;
      plugins.mpvpaperWallpaper.enable = osConfig.networking.hostName == "Lukes-Um790";
    };
  };
}
