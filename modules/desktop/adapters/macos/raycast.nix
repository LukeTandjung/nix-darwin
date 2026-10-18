{ inputs, ... }:
{
  modules.darwin.raycast = { pkgs, lib, ... }:
    let
      enable = false;
    in
    lib.mkIf enable {
      environment.systemPackages = [ pkgs.raycast ];
    };
}
