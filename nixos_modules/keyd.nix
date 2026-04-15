{ config, lib, ... }:
lib.mkIf (config.networking.hostName == "Lukes-Um790") {
  # Apple Magic Keyboard: make media keys (brightness, volume, etc.) the default
  # behavior for the function row. Hold Fn for F1-F12.
  boot.extraModprobeConfig = ''
    options hid_apple fnmode=1
  '';

  # Globe key: tap → scrolllock (bound in Hyprland to cycle keyboard layouts),
  # hold → activates "globe" layer for globe+shift+c/v copy/paste.
  # To enable input language switching, add a second layout to kb_layout
  # in hyprland.nix, e.g. kb_layout = "us,jp"
  #
  # Lock key (coffee/XF86ScreenSaver) is handled in Hyprland bindings.
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings = {
        main = {
          fn = "leftcontrol";
        };
      };
    };
  };
}
