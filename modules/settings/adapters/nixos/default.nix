{ config, ... }:
{
  adapters.settings.nixos = {
    platform = "nixos";
    system.imports = with config.modules.nixos; [
      ssh hardware audio network power users packages theme nix fwupd nix-ld keyboard nvidia
    ];
    home.imports = [ config.modules.hjem.ssh config.modules.hjem.theme ];
  };
}
