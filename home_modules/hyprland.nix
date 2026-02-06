{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
lib.mkIf pkgs.stdenv.isLinux {
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      monitor = [
        "eDP-1,preferred,auto,auto"
        "DP-3,preferred,auto,auto,mirror,eDP-1"
      ];

      # Variables
      "$terminal" = "kitty";
      "$fileManager" = "nautilus";
      "$menu" = "dms ipc call spotlight toggle";
      "$mainMod" = "ALT";

      # Autostart
      "exec-once" = [
        "bash -c \"wl-paste --watch cliphist store &\""
        "dms run & hyprctl setcursor catppuccin-frappe-blue-cursors 24"
      ];

      # Environment
      env = [
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_SIZE,24"
        "XCURSOR_THEME,catppuccin-frappe-blue-cursors"
        "HYPRCURSOR_THEME,catppuccin-frappe-blue-cursors"
      ];

      general = {
        gaps_in = 5;
        gaps_out = 5;
        border_size = 1;
        resize_on_border = false;
        allow_tearing = false;
        layout = "dwindle";
      };

      decoration = {
        rounding = 10;
        active_opacity = 1.0;
        inactive_opacity = 0.8;

        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
        };

        blur = {
          enabled = true;
          size = 3;
          passes = 1;
          vibrancy = 0.1696;
        };
      };

      animations = {
        # Hyprland accepts fun yes/no; keep as string to preserve syntax
        enabled = "yes, please :)";

        bezier = [
          "easeOutQuint,0.23,1,0.32,1"
          "easeInOutCubic,0.65,0.05,0.36,1"
          "linear,0,0,1,1"
          "almostLinear,0.5,0.5,0.75,1.0"
          "quick,0.15,0,0.1,1"
        ];

        animation = [
          "global, 1, 10, default"
          "border, 1, 5.39, easeOutQuint"
          "windows, 1, 4.79, easeOutQuint"
          "windowsIn, 1, 4.1, easeOutQuint, popin 87%"
          "windowsOut, 1, 1.49, linear, popin 87%"
          "fadeIn, 1, 1.73, almostLinear"
          "fadeOut, 1, 1.46, almostLinear"
          "fade, 1, 3.03, quick"
          "layers, 1, 3.81, easeOutQuint"
          "layersIn, 1, 4, easeOutQuint, fade"
          "layersOut, 1, 1.5, linear, fade"
          "fadeLayersIn, 1, 1.79, almostLinear"
          "fadeLayersOut, 1, 1.39, almostLinear"
          "workspaces, 1, 1.94, almostLinear, fade"
          "workspacesIn, 1, 1.21, almostLinear, fade"
          "workspacesOut, 1, 1.94, almostLinear, fade"
        ];
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      master = {
        new_status = "master";
      };

      misc = {
        force_default_wallpaper = -1;
        disable_hyprland_logo = false;
      };

      cursor = {
        enable_hyprcursor = true;
        no_hardware_cursors = 1;
      };

      input = {
        kb_layout = "us";
        kb_variant = "";
        kb_model = "";
        kb_options = "";
        kb_rules = "";
        follow_mouse = 1;
        sensitivity = 0;

        touchpad = {
          natural_scroll = false;
        };
      };

      device = [
        {
          name = "epic-mouse-v1";
          sensitivity = -0.5;
        }
      ];

      # Binds
      bind = [
        "$mainMod, Q, exec, $terminal"
        "$mainMod, X, killactive,"
        "$mainMod, E, exec, $fileManager"
        "$mainMod, V, togglefloating,"
        "$mainMod, R, exec, $menu"
        "$mainMod, J, togglesplit,"

        # DankMaterialShell specific binds
        "$mainMod, C, exec, dms ipc call clipboard toggle"
        "$mainMod, N, exec, dms ipc call notifications toggle"
        "$mainMod, comma, exec, dms ipc call settings toggle"
        "$mainMod, M, exec, dms ipc call notepad toggle"
        "$mainMod, L, exec, dms ipc call lock lock"
        "$mainMod, XF86PowerOff, exec, dms ipc call powermenu toggle"
        "$mainMod, W, exec, dms ipc call dankdash wallpaper"
        "$mainMod, TAB, exec, dms ipc call hypr toggleOverview"

        # Focus movement
        "$mainMod, left, movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up, movefocus, u"
        "$mainMod, down, movefocus, d"

        # Workspaces 1-10
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"

        # Move window to workspace
        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"

        # Special workspace
        "$mainMod, S, togglespecialworkspace, magic"
        "$mainMod SHIFT, S, movetoworkspace, special:magic"

        # Scroll through workspaces
        "$mainMod, mouse_down, workspace, e+1"
        "$mainMod, mouse_up, workspace, e-1"

        # Screenshot settings
        "$mainMod, PRINT, exec, hyprshot -m window"
        ", PRINT, exec, hyprshot -m output"
        "$mainMod SHIFT, PRINT, exec, hyprshot -m region"
      ];

      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];

      bindel = [
        ",XF86AudioRaiseVolume, exec, dms ipc call audio increment 5"
        ",XF86AudioLowerVolume, exec, dms ipc call audio decrement 5"
        ",XF86AudioMute, exec, dms ipc call audio mute"
        ",XF86AudioMicMute, exec, dms ipc call audio micmute"
        ",XF86MonBrightnessUp, exec, dms ipc call brightness increment 5 backlight:intel_backlight"
        ",XF86MonBrightnessDown, exec, dms ipc call brightness decrement 5 backlight:intel_backlight"
      ];

      bindl = [
        ",XF86AudioNext, exec, playerctl next"
        ",XF86AudioPause, exec, playerctl play-pause"
        ",XF86AudioPlay, exec, playerctl play-pause"
        ",XF86AudioPrev, exec, playerctl previous"
      ];

      # Window and workspace rules
      windowrule = [
        "no_focus on, match:class ^$, match:title ^$, match:xwayland true, match:floating true, match:fullscreen false, match:pinned false"
      ];
    };
  };
}
