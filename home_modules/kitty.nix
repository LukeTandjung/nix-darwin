{
  pkgs,
  ...
}:
{
  programs.kitty = {
    enable = true;
    package = pkgs.kitty;
    settings = {
      macos_option_as_alt = "yes";
      enabled_layouts = "horizontal";

      # Disable kitty's automatic config watcher.
      # Stylix generates kitty theme includes in /nix/store; kitty's watcher can
      # recursively watch large parts of the store and exhaust inotify watches.
      # Config is managed by Nix/Home Manager, so manual reloads or new windows are enough.
      auto_reload_config = "no";
    };
  };
}
