{ inputs, ... }:
{
  modules.home.vesktop =
    { pkgs, ... }:
    {
      programs.vesktop = {
        enable = true;
        package = pkgs.vesktop;
      };
    };
}
