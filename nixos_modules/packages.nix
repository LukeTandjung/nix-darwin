{ pkgs, ... }:

{
  # Core system packages
  environment.systemPackages = with pkgs; [
    git
    wget
  ];

  # Fonts
  fonts.packages = with pkgs; [
    font-awesome
    jetbrains-mono
    ibm-plex
  ];
}
