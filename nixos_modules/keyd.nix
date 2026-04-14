{ config, lib, ... }:
lib.mkIf (config.networking.hostName == "Lukes-Um790") {
  # Apple Magic Keyboard: make media keys (brightness, volume, etc.) the default
  # behavior for the function row. Hold Fn for F1-F12.
  boot.extraModprobeConfig = ''
    options hid_apple fnmode=1
  '';

  # Low-level key remapping via keyd for Mac-like shortcuts.
  #
  # Globe/Fn key: the Apple Magic Keyboard globe key may not generate a
  # standard input event on Linux. Run `sudo keyd monitor` to check.
  # If it shows up (e.g. as `fn`), add a mapping in settings.main to
  # trigger input language switching via Hyprland:
  #   1. Set kb_layout = "us,<second>" in hyprland.nix input section
  #   2. Map the globe key here to a unique key (e.g. fn = scrolllock)
  #   3. Bind that key in Hyprland to: hyprctl switchxkblayout all next
  #
  # The meta (Cmd) layer remaps Cmd+C/V to Ctrl+C/V for copy/paste.
  # Note: Hyprland's SUPER+C (clipboard toggle) and SUPER+V (toggle floating)
  # will no longer trigger from Cmd+C/V. Rebind those in hyprland.nix if needed.
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings.meta = {
        c = "C-c";
        v = "C-v";
      };
    };
  };
}
