{ config, ... }:
{
  adapters.desktop.macos = {
    platform = "darwin";
    system.imports = [
      config.modules.darwin.jankyborders
      config.modules.darwin.raycast
    ];
    home.imports = [
      config.modules.home.aerospace
    ];
  };
}
