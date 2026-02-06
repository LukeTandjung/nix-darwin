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
        hash = "";
      };
    };
  };
}
