{ ... }:
{
  modules.hjem.hyprshot = { pkgs, ... }: {
    packages = [ pkgs.hyprshot ];
    environment.sessionVariables.HYPRSHOT_DIR = "$HOME/Screenshots";
  };
}
