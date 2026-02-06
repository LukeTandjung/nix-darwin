{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: lib.mkIf pkgs.stdenv.isLinux {
  programs.dank-material-shell = {
    enable = true;
    enableCalendarEvents = false;
    plugins.dms-power-usage = {
      src = pkgs.fetchFromGitHub {
        owner = "Daniel-42-z";
        repo = "dms-power-usage";
        rev = "main";
        hash = "sha256-9lMWVCiAW+0fAZD4dXGhE+6f8d1/4DHejfUumfoHY2s=";
      };
    };
  };
}
