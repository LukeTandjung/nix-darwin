{ pkgs, rnote-nixpkgs, ... }:
let
  rnote-pkgs = import rnote-nixpkgs { system = pkgs.stdenv.hostPlatform.system; };
in
{
  environment.systemPackages = [
    rnote-pkgs.rnote
  ];
}
