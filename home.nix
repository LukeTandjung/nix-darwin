{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  home.username = "luketandjung";
  home.homeDirectory = "/Users/luketandjung"; # Standard macOS home directory path
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  imports = [
    ./home_modules
  ];

  # --- Package Management ---
  home.packages = [ ];

  # This suppresses the login message that appears for Kitty!
  home.file.".hushlogin".text = "";
}
