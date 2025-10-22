{ inputs, pkgs, ... }:

{
  # Display manager
  services.displayManager.gdm.enable = true;

  # Hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Terminal
  environment.sessionVariables.TERMINAL = "kitty";

  # Desktop packages
  environment.systemPackages = with pkgs; [
    nautilus
    wl-clipboard
    cliphist
    cava
    hyprcursor
    catppuccin-cursors.frappeBlue
    imagemagick
    brightnessctl
    playerctl
  ];
}
