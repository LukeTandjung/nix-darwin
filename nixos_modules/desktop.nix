{ pkgs, ... }:

{
  # Display manager when you first login!
  services.displayManager.gdm.enable = false;
  services.displayManager.dms-greeter = {
    enable = true;
    compositor.name = "hyprland";
    configHome = "/home/luke";
    logs = {
      save = true;
      path = "/tmp/dms-greeter.log";
    };
  };

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
