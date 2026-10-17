{ inputs, ... }:
{
  modules.home.hyprshot =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      programs.hyprshot = {
        enable = true;
        package = pkgs.hyprshot;
        saveLocation = "$HOME/Screenshots";
      };
    };
}
