{
  osConfig,
  pkgs,
  lib,
  ...
}:
let
  hostName = osConfig.networking.hostName;
  isUm790 = hostName == "Lukes-Um790";
  brightnessDevice = if hostName == "Lukes-Mac-air" then " backlight:intel_backlight" else "";
  mainMod = if hostName == "Lukes-Mac-air" then "ALT" else "SUPER";
in
lib.mkIf pkgs.stdenv.isLinux {
  home.pointerCursor = {
    package = pkgs.adwaita-icon-theme;
    name = "Adwaita";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # Home Manager's Hyprland module also manages xdg-desktop-portal.
  # Add the GTK portal here so the active user portal dir includes OpenURI.
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";

    settings = {
      monitor = [
        {
          output = "eDP-1";
          mode = "preferred";
          position = "auto";
          scale = "auto";
        }
        {
          output = "DP-3";
          mode = "preferred";
          position = "auto";
          scale = "auto";
          mirror = "eDP-1";
        }
        {
          output = "HDMI-A-1";
          mode = "1920x1080@144";
          position = "0x0";
          scale = 1;
        }
      ];

      env = [
        { _args = [ "XCURSOR_SIZE" "24" ]; }
        { _args = [ "XCURSOR_THEME" "Adwaita" ]; }
        { _args = [ "HYPRCURSOR_SIZE" "24" ]; }
        { _args = [ "HYPRCURSOR_THEME" "Adwaita" ]; }
        { _args = [ "QT_QPA_PLATFORM" "wayland" ]; }
        { _args = [ "ELECTRON_OZONE_PLATFORM_HINT" "auto" ]; }
        { _args = [ "QT_QPA_PLATFORMTHEME" "gtk3" ]; }
        { _args = [ "QT_QPA_PLATFORMTHEME_QT6" "gtk3" ]; }
      ];

      config = {
        general = {
          gaps_in = 5;
          gaps_out = 5;
          border_size = 1;
          resize_on_border = false;
          allow_tearing = true;
          layout = "dwindle";
        };

        decoration = {
          rounding = 6;
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

        dwindle = {
          preserve_split = true;
        };

        master = {
          new_status = "master";
        };

        misc = {
          force_default_wallpaper = -1;
          disable_hyprland_logo = false;
          vrr = 2;
        };

        cursor = {
          enable_hyprcursor = false;
          no_hardware_cursors = 0;
        };

        input = {
          kb_layout = "us";
          kb_variant = "";
          kb_model = "";
          kb_options = "";
          kb_rules = "";
          follow_mouse = 1;
          sensitivity = 0;
          accel_profile = "flat";

          touchpad = {
            natural_scroll = false;
          };
        };

      };
    };

    extraConfig = ''
      local terminal = "kitty"
      local fileManager = "nautilus"
      local menu = "dms ipc call spotlight toggle"
      local mainMod = "${mainMod}"
      local lockCommand = "sh -lc 'timeout 2 dms ipc call lock lock || loginctl lock-session'"

      hl.device({
        name = "epic-mouse-v1",
        sensitivity = -0.5,
      })

      -- Hyprland 0.55 Lua config uses explicit curve/animation calls instead
      -- of hyprlang-style animation strings. Speeds are deciseconds, so 2.0 is
      -- about 200ms.
      hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
      hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
      hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
      hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

      hl.animation({ leaf = "global", enabled = true, speed = 1.0, bezier = "default" })
      hl.animation({ leaf = "border", enabled = true, speed = 2.0, bezier = "easeOutQuint" })
      hl.animation({ leaf = "windows", enabled = true, speed = 2.0, bezier = "easeOutQuint" })
      hl.animation({ leaf = "windowsIn", enabled = true, speed = 2.0, bezier = "easeOutQuint", style = "popin 87%" })
      hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.0, bezier = "linear", style = "popin 87%" })
      hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.0, bezier = "almostLinear" })
      hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.0, bezier = "almostLinear" })
      hl.animation({ leaf = "fade", enabled = true, speed = 1.5, bezier = "quick" })
      hl.animation({ leaf = "layers", enabled = true, speed = 2.0, bezier = "easeOutQuint" })
      hl.animation({ leaf = "layersIn", enabled = true, speed = 2.0, bezier = "easeOutQuint", style = "fade" })
      hl.animation({ leaf = "layersOut", enabled = true, speed = 1.0, bezier = "linear", style = "fade" })
      hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.0, bezier = "almostLinear" })
      hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.0, bezier = "almostLinear" })
      hl.animation({ leaf = "workspaces", enabled = true, speed = 1.5, bezier = "almostLinear", style = "fade" })
      hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.2, bezier = "almostLinear", style = "fade" })
      hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.5, bezier = "almostLinear", style = "fade" })

      hl.on("hyprland.start", function()
        hl.exec_cmd("hyprctl setcursor Adwaita 24")
        hl.exec_cmd("bash -c 'wl-paste --watch cliphist store &'")
        hl.exec_cmd("dms run &")
      end)

      hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
      hl.bind(mainMod .. " + X", hl.dsp.window.close())
      hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
      hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
      hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen(0))
      hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
      hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

      -- DankMaterialShell specific binds
      hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("dms ipc call clipboard toggle"))
      hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("dms ipc call notifications toggle"))
      hl.bind(mainMod .. " + comma", hl.dsp.exec_cmd("dms ipc call settings toggle"))
      hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("dms ipc call notepad toggle"))
      hl.bind(mainMod .. " + L", hl.dsp.exec_cmd(lockCommand))
      hl.bind(mainMod .. " + XF86PowerOff", hl.dsp.exec_cmd("dms ipc call powermenu toggle"))
      hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("dms ipc call dankdash wallpaper"))
      hl.bind(mainMod .. " + TAB", hl.dsp.exec_cmd("dms ipc call hypr toggleOverview"))

      -- Focus movement
      hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
      hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
      hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
      hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

      -- Move active window within workspace
      hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.move({ direction = "left" }))
      hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
      hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.move({ direction = "up" }))
      hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.move({ direction = "down" }))

      -- Workspaces 1-5
      for i = 1, 5 do
        local key = tostring(i)
        hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
        hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
      end

      -- Special workspace
      hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
      hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

      -- Scroll through workspaces
      hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
      hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

      -- Screenshot settings
      hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd("hyprshot -m window"))
      hl.bind("PRINT", hl.dsp.exec_cmd("hyprshot -m output"))
      hl.bind(mainMod .. " + SHIFT + PRINT", hl.dsp.exec_cmd("hyprshot -m region"))

      ${lib.optionalString isUm790 ''
      -- Apple Magic Keyboard special keys (Um790 only)
      hl.bind("XF86Search", hl.dsp.exec_cmd("dms ipc call spotlight toggle"))
      -- Apple Magic Keyboard lock emits XF86ScreenSaver, but it can arrive as
      -- a release-only / modifier-tainted event, so match it more loosely than
      -- normal letter binds.
      hl.bind("XF86ScreenSaver", hl.dsp.exec_cmd(lockCommand), { locked = true, release = true, ignore_mods = true })
      hl.bind(mainMod .. " + XF86LaunchA", hl.dsp.exec_cmd("hyprshot -m window"))
      hl.bind("XF86LaunchA", hl.dsp.exec_cmd("hyprshot -m output"))
      hl.bind(mainMod .. " + SHIFT + XF86LaunchA", hl.dsp.exec_cmd("hyprshot -m region"))
      ''}

      -- Mouse binds
      hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
      hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

      -- Media and brightness keys
      hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("dms ipc call audio increment 5"), { locked = true, repeating = true })
      hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("dms ipc call audio decrement 5"), { locked = true, repeating = true })
      hl.bind("XF86AudioMute", hl.dsp.exec_cmd("dms ipc call audio mute"), { locked = true })
      hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("dms ipc call audio micmute"), { locked = true })
      hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("dms ipc call brightness increment 5${brightnessDevice}"), { locked = true, repeating = true })
      hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("dms ipc call brightness decrement 5${brightnessDevice}"), { locked = true, repeating = true })

      hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
      hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
      hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
      hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

      -- Window and workspace rules
      hl.window_rule({
        name = "fix-xwayland-empty-drags",
        match = {
          class = "^$",
          title = "^$",
          xwayland = true,
          float = true,
          fullscreen = false,
          pin = false,
        },
        no_focus = true,
      })

      -- Allow screen tearing for CS2 to reduce input latency
      hl.window_rule({
        name = "cs2-immediate",
        match = { class = "^(cs2)$" },
        immediate = true,
      })
    '';
  };
}
