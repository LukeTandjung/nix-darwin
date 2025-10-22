{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
in
{
  home.username = if isDarwin then "luketandjung" else "luke";
  home.homeDirectory = if isDarwin then "/Users/luketandjung" else "/home/luke";
  programs.home-manager.enable = true;
  imports = [
    ./home_modules
  ];
  home.packages = [ ];
}
