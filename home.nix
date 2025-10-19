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
  home.homeDirectory = if isDarwin then "/Users/luketandjung" else "/home/luke"; # Standard macOS home directory path

  programs.home-manager.enable = true;

  imports = [
    ./home_modules
  ];

  # --- Package Management ---
  home.packages = [ ];

  # This suppresses the login message that appears for Kitty!
  home.file.".hushlogin".text = "";
}
