{ config, ... }:
{
  adapters.settings.darwin = {
    platform = "darwin";
    system.imports = with config.modules.darwin; [ nix theme system-defaults keepassxc helium-browser ];
    home.imports = [ config.modules.hjem.ssh config.modules.hjem.theme ];
  };
}
