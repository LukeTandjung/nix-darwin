{ pkgs, ... }:

{
  # Core system packages
  environment.systemPackages = with pkgs; [
    git
    wget
    upower
    brave
    firefox
  ];

  # Fonts
  fonts.packages = with pkgs; [
    font-awesome
    jetbrains-mono
    ibm-plex
  ];
}
