{ config, inputs, ... }:
{
  adapters.settings.darwin = {
    platform = "darwin";
    system.imports = [
      inputs.stylix.darwinModules.stylix
    ]
    ++ (with config.modules.darwin; [
      nix
      stylix
      system-defaults
    ]);
    home.imports = [ config.modules.home.ssh ];
  };
}
