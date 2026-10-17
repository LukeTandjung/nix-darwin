{ inputs, ... }:
{
  modules.nixos.power =
    { ... }:
    {
      services.upower = {
        enable = true;
      };
    };
}
