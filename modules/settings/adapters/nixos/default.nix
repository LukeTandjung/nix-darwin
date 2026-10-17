{ config, inputs, ... }:
{
  adapters.settings.nixos = {
    platform = "nixos";
    system.imports = [
      inputs.stylix.nixosModules.stylix
    ]
    ++ (with config.modules.nixos; [
      ssh
      hardware
      audio
      network
      power
      users
      packages
      stylix
      nix
      fwupd
      nix-ld
      keyboard
      nvidia
    ]);
    home.imports = [ config.modules.home.ssh ];
  };
}
