{ config, inputs, ... }:
{
  adapters.desktop.linux = {
    platform = "nixos";
    system.imports = [
      config.modules.nixos.desktop-session
    ];
    home.imports = [
      config.modules.hjem.dank-material-shell
      config.modules.hjem.hyprland
      config.modules.hjem.hyprshot
      config.modules.hjem.mpvpaper
    ];
  };
}
