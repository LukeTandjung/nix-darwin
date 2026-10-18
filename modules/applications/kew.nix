{ inputs, ... }:
{
  modules.nixos.kew = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.kew ];
  };
}
