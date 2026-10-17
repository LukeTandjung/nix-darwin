{ inputs, ... }:
{
  modules.nixos.docker =
    { ... }:

    {
      virtualisation.docker = {
        enable = true;
        enableOnBoot = true;
      };
    };
}
