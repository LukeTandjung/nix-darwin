{
  config,
  pkgs,
  lib,
  ...
}:
lib.mkIf pkgs.stdenv.isDarwin {
  programs.aerospace = {
    enable = true;

    settings = {
      config-version = 2;
      start-at-login = true;

      default-root-container-layout = "tiles";
      default-root-container-orientation = "auto";
      accordion-padding = 30;

      gaps = {
        inner = {
          horizontal = 16;
          vertical = 16;
        };
        outer = {
          left = 16;
          bottom = 16;
          top = 56; # 40 (external bar) + 16 (padding)
          right = 16;
        };
      };

      # NOTE: The following yabai features have no AeroSpace equivalent:
      #   - focus_follows_mouse = "autoraise"
      #   - window_opacity (active/normal)
      #   - menubar_opacity = 0.0

      persistent-workspaces = [ "1" "2" "3" "4" "5" ];

      mode.main.binding = {
        # Window focus (cmd + arrow)
        cmd-left = "focus left";
        cmd-down = "focus down";
        cmd-up = "focus up";
        cmd-right = "focus right";

        # Window move/warp (cmd + shift + arrow)
        cmd-shift-left = "move left";
        cmd-shift-down = "move down";
        cmd-shift-up = "move up";
        cmd-shift-right = "move right";

        # Resize (cmd + minus/equal)
        cmd-minus = "resize smart -50";
        cmd-equal = "resize smart +50";

        # Workspace focus (cmd + 1-5)
        cmd-1 = "workspace 1";
        cmd-2 = "workspace 2";
        cmd-3 = "workspace 3";
        cmd-4 = "workspace 4";
        cmd-5 = "workspace 5";

        # Move window to workspace + focus (cmd + shift + 1-5)
        cmd-shift-1 = [ "move-node-to-workspace 1" "workspace 1" ];
        cmd-shift-2 = [ "move-node-to-workspace 2" "workspace 2" ];
        cmd-shift-3 = [ "move-node-to-workspace 3" "workspace 3" ];
        cmd-shift-4 = [ "move-node-to-workspace 4" "workspace 4" ];
        cmd-shift-5 = [ "move-node-to-workspace 5" "workspace 5" ];

        # Open kitty (cmd + q)
        cmd-q = "exec-and-forget open -na kitty";

        # Open kitty with yazi (cmd + e)
        cmd-e = "exec-and-forget open -na kitty --args zsh -lc yazi";

        # Close focused window (cmd + x)
        cmd-x = "close";
      };
    };
  };
}
