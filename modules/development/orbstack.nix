{ ... }:
{
  modules.darwin.orbstack = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.orbstack ];
  };
}
