{ pkgs, ... }:

{
  # Display manager when you first login!
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
    playerctl

    # These are Framework 12 specific settings!
    iio-sensor-proxy
    iio-hyprland
    libinput
  ];

  # xdg portal settings for desktop configuration
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
  };
}
