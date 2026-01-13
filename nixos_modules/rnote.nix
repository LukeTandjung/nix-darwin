{ pkgs, rnote-nixpkgs, ... }:
let
  rnote-pkgs = import rnote-nixpkgs { system = pkgs.system; };
in
{
  environment.systemPackages = [
    rnote-pkgs.rnote
  ];
}
