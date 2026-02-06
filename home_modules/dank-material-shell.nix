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
        wallpaperPath = "/home/luke/Pictures/Wallpapers";
        barConfigs = [
          {
            id = "default";
            name = "Main Bar";
            enabled = true;
            position = 0;
            screenPreferences = [ "all" ];
            showOnLastDisplay = true;
            leftWidgets = [ "launcherButton" "workspaceSwitcher" "focusedWindow" ];
            centerWidgets = [ "music" "clock" "weather" ];
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
        weatherLocation = "London, UK";
        weatherCoordinates = "51.5074,-0.1278";
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
