{ pkgs, lib, ... }:
let
  enable = false;
in
lib.mkIf enable {
  environment.systemPackages = with pkgs; [
    raycast
  ];
}
