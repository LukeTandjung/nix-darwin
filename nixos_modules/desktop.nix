{ inputs, pkgs, ... }:

{
  # Display manager
  services.xserver.displayManager.gdm.enable = true;

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
    hyprcursor
    catppuccin-cursors.frappeBlue
    imagemagick
    brightnessctl
    dank-material-shell.packages.${pkgs.system}.default
  ];
}
