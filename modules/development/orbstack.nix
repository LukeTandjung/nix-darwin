{ inputs, ... }:
{
  modules.darwin.orbstack =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        orbstack
      ];
    };
}
