{ pkgs, inputs, ... }:

{
  # Core system packages
  environment.systemPackages = with pkgs; [
    wget
    upower
  ];

  # Fonts
  fonts.packages = [
    inputs.luke-pkgs.packages.${pkgs.system}.terminal_grotesque
  ]
  ++ (with pkgs; [
    font-awesome
    jetbrains-mono
    ibm-plex
  ]);
}
