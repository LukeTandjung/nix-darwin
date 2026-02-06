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
        showClipboard = false;
        launcherLogoMode = "os";
        launcherLogoColorOverride = "primary";
        appLauncherViewMode = "grid";
        spotlightModalViewMode = "grid";
        barConfigs = [
          {
            id = "default";
            position = 0;
            screenPreferences = [ "all" ];
            showOnLastDisplay = true;
            leftWidgets = [ "launcherButton" "workspaceSwitcher" "focusedWindow" ];
            centerWidgets = [ "music" "clock" "weather" ];
            rightWidgets = [ "systemTray" "cpuUsage" "memUsage" "notificationButton" "battery" "controlCenterButton" ];
            spacing = 4;
            innerPadding = 4;
            bottomGap = 0;
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
