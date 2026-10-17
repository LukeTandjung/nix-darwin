{ inputs, ... }:
{
  modules.nixos.network =
    { config, lib, ... }:

    {
      networking = {
        networkmanager.enable = true;
      };
    };
}
