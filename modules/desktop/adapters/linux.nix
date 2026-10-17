{ config, inputs, ... }:
{
  adapters.desktop.linux = {
    platform = "nixos";
    system.imports = [
      config.modules.nixos.desktop-session
    ];
    home.imports = [
      inputs.dankMaterialShell.homeModules.dank-material-shell
      inputs.dms-plugin-registry.homeModules.default
      inputs.dsearch.homeModules.default
      config.modules.home.dank-material-shell
      config.modules.home.hyprland
      config.modules.home.hyprshot
      config.modules.home.mpvpaper
    ];
  };
}
