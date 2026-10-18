{ inputs, ... }:
{
  modules.nixos.evince = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.evince ];
  };
}
