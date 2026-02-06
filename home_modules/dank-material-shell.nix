{
  pkgs,
  lib,
  ...
}:
lib.mkIf pkgs.stdenv.isLinux {
  programs = {
    dsearch.enable = true;

    dank-material-shell = {
      enable = true;
      enableCalendarEvents = false;
      settings = {
        fontFamily = "JetBrains Mono";
        cornerRadius = 6;
        showWorkspaceApps = true;
        showClipboard = true;
        launcherLogoMode = "os";
        launcherLogoColorOverride = "primary";
        wallpaperPath = "/home/luke/Pictures/Wallpapers/painting_in_balcony.jpeg";
        barConfigs = [
          {
            id = "default";
            name = "Main Bar";
            enabled = true;
            position = 0;
            screenPreferences = [ "all" ];
            showOnLastDisplay = true;
            leftWidgets = [
              "launcherButton"
              "workspaceSwitcher"
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
              "memUsage"
              "notificationButton"
              "battery"
              "controlCenterButton"
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
          }
        ];
      };
      session = {
        isLightMode = false;
        doNotDisturb = false;
        perMonitorWallpaper = false;
        monitorWallpapers = { };
        perModeWallpaper = false;
        wallpaperPathLight = "";
        wallpaperPathDark = "";
        monitorWallpapersLight = { };
        monitorWallpapersDark = { };
        wallpaperTransition = "fade";
        includedTransitions = [
          "fade"
          "wipe"
          "disc"
          "stripes"
          "iris bloom"
          "pixelate"
          "portal"
        ];
        wallpaperCyclingEnabled = true;
        wallpaperCyclingMode = "interval";
        wallpaperCyclingInterval = 1800;
        wallpaperCyclingTime = "06:00";
        monitorCyclingSettings = { };
        nightModeEnabled = true;
        nightModeTemperature = 4500;
        nightModeHighTemperature = 6500;
        nightModeAutoEnabled = true;
        nightModeAutoMode = "time";
        nightModeStartHour = 21;
        nightModeStartMinute = 0;
        nightModeEndHour = 6;
        nightModeEndMinute = 0;
        latitude = 0;
        longitude = 0;
        nightModeUseIPLocation = false;
        nightModeLocationProvider = "";
        themeModeAutoEnabled = false;
        themeModeAutoMode = "time";
        themeModeStartHour = 22;
        themeModeStartMinute = 0;
        themeModeEndHour = 6;
        themeModeEndMinute = 0;
        themeModeShareGammaSettings = true;
        weatherLocation = "London, UK";
        weatherCoordinates = "51.5074,-0.1278";
        pinnedApps = [ ];
        barPinnedApps = [ ];
        dockLauncherPosition = 0;
        hiddenTrayIds = [ ];
        trayItemOrder = [ ];
        recentColors = [ ];
        showThirdPartyPlugins = false;
        launchPrefix = "";
        lastBrightnessDevice = "";
        brightnessExponentialDevices = { };
        brightnessUserSetValues = { };
        brightnessExponentValues = { };
        selectedGpuIndex = 0;
        nvidiaGpuTempEnabled = false;
        nonNvidiaGpuTempEnabled = false;
        enabledGpuPciIds = [ ];
        wifiDeviceOverride = "";
        weatherHourlyDetailed = true;
        hiddenApps = [ ];
        appOverrides = { };
        searchAppActions = true;
        vpnLastConnected = "";
        configVersion = 3;
      };
      plugins.dms-power-usage = {
        src = pkgs.fetchFromGitHub {
          owner = "Daniel-42-z";
          repo = "dms-power-usage";
          rev = "main";
          hash = "sha256-9lMWVCiAW+0fAZD4dXGhE+6f8d1/4DHejfUumfoHY2s=";
        };
      };
    };
  };
}
