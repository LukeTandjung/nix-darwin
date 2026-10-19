{ ... }:
{
  modules.hjem.hyprland = { config, osConfig, pkgs, lib, theme, ... }:
    let
      hostName = osConfig.networking.hostName;
      isUm790 = hostName == "Lukes-Um790";
      brightnessDevice = if hostName == "Lukes-Mac-air" then " backlight:intel_backlight" else "";
      mainMod = if hostName == "Lukes-Mac-air" then "ALT" else "SUPER";

      settings = {
        monitor = [
          {
            output = "desc:Microstep MSI G24C4 0x0000041C";
            mode = "1920x1080@144";
            position = "auto";
            scale = 1;
          }
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
          {
            _args = [ "XCURSOR_SIZE" "24" ];
          }
          {
            _args = [ "XCURSOR_THEME" "Adwaita" ];
          }
          {
            _args = [ "HYPRCURSOR_SIZE" "24" ];
          }
          {
            _args = [ "HYPRCURSOR_THEME" "Adwaita" ];
          }
          {
            _args = [ "QT_QPA_PLATFORM" "wayland" ];
          }
          {
            _args = [ "ELECTRON_OZONE_PLATFORM_HINT" "auto" ];
          }
          {
            _args = [ "QT_QPA_PLATFORMTHEME" "gtk3" ];
          }
          {
            _args = [ "QT_QPA_PLATFORMTHEME_QT6" "gtk3" ];
          }
        ];

        config = {
          general = {
            gaps_in = 5;
            gaps_out = 5;
            border_size = 1;
            "col.active_border" = "rgb(${theme.palette.base0D})";
            "col.inactive_border" = "rgb(${theme.palette.base03})";
            resize_on_border = false;
            allow_tearing = true;
            layout = "dwindle";
          };

          decoration = {
            rounding = 6;
            active_opacity = 1.0;
            inactive_opacity = 0.8;

            shadow = {
              color = "rgba(${theme.palette.base00}99)";
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

          group = {
            "col.border_active" = "rgb(${theme.palette.base0D})";
            "col.border_inactive" = "rgb(${theme.palette.base03})";
            "col.border_locked_active" = "rgb(${theme.palette.base0C})";
            groupbar = {
              "col.active" = "rgb(${theme.palette.base0D})";
              "col.inactive" = "rgb(${theme.palette.base03})";
              text_color = "rgb(${theme.palette.base05})";
            };
          };
          misc = {
            background_color = "rgb(${theme.palette.base00})";
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
        local terminal = "tern"
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

        -- Register both profiles from one binding list; only Tern's chords differ.
        local desktopBindings = {}
        local function bind(keys, dispatcher, options)
          table.insert(desktopBindings, { keys = keys, dispatcher = dispatcher, options = options })
        end

        bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
        bind(mainMod .. " + X", hl.dsp.window.close())
        bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
        bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
        bind(mainMod .. " + F", hl.dsp.window.fullscreen(0))
        bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
        bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

        -- DankMaterialShell specific binds
        bind(mainMod .. " + C", hl.dsp.exec_cmd("dms ipc call clipboard toggle"))
        bind(mainMod .. " + N", hl.dsp.exec_cmd("dms ipc call notifications toggle"))
        bind(mainMod .. " + comma", hl.dsp.exec_cmd("dms ipc call settings toggle"))
        bind(mainMod .. " + M", hl.dsp.exec_cmd("dms ipc call notepad toggle"))
        bind(mainMod .. " + L", hl.dsp.exec_cmd(lockCommand))
        bind(mainMod .. " + XF86PowerOff", hl.dsp.exec_cmd("dms ipc call powermenu toggle"))
        bind(mainMod .. " + W", hl.dsp.exec_cmd("dms ipc call dankdash wallpaper"))
        bind(mainMod .. " + TAB", hl.dsp.exec_cmd("dms ipc call hypr toggleOverview"))

        -- Focus movement
        bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
        bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
        bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
        bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

        -- Move active window within workspace
        bind(mainMod .. " + SHIFT + left", hl.dsp.window.move({ direction = "left" }))
        bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
        bind(mainMod .. " + SHIFT + up", hl.dsp.window.move({ direction = "up" }))
        bind(mainMod .. " + SHIFT + down", hl.dsp.window.move({ direction = "down" }))

        -- Workspaces 1-5
        for i = 1, 5 do
          local key = tostring(i)
          bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
          bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
        end

        -- Special workspace
        bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
        bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

        -- Scroll through workspaces
        bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
        bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

        -- Screenshot settings
        bind(mainMod .. " + PRINT", hl.dsp.exec_cmd("hyprshot -m window"))
        bind("PRINT", hl.dsp.exec_cmd("hyprshot -m output"))
        bind(mainMod .. " + SHIFT + PRINT", hl.dsp.exec_cmd("hyprshot -m region"))

        ${lib.optionalString isUm790 ''
          -- Apple Magic Keyboard special keys (Um790 only)
          bind("XF86Search", hl.dsp.exec_cmd("dms ipc call spotlight toggle"))
          -- Apple Magic Keyboard lock emits XF86ScreenSaver, but it can arrive as
          -- a release-only / modifier-tainted event, so match it more loosely than
          -- normal letter binds.
          bind("XF86ScreenSaver", hl.dsp.exec_cmd(lockCommand), { locked = true, release = true, ignore_mods = true })
          bind(mainMod .. " + XF86LaunchA", hl.dsp.exec_cmd("hyprshot -m window"))
          bind("XF86LaunchA", hl.dsp.exec_cmd("hyprshot -m output"))
          bind(mainMod .. " + SHIFT + XF86LaunchA", hl.dsp.exec_cmd("hyprshot -m region"))
        ''}

        -- Mouse binds
        bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
        bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

        -- Media and brightness keys
        bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("dms ipc call audio increment 5"), { locked = true, repeating = true })
        bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("dms ipc call audio decrement 5"), { locked = true, repeating = true })
        bind("XF86AudioMute", hl.dsp.exec_cmd("dms ipc call audio mute"), { locked = true })
        bind("XF86AudioMicMute", hl.dsp.exec_cmd("dms ipc call audio micmute"), { locked = true })
        bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("dms ipc call brightness increment 5${brightnessDevice}"), { locked = true, repeating = true })
        bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("dms ipc call brightness decrement 5${brightnessDevice}"), { locked = true, repeating = true })

        bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
        bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
        bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
        bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

        local ternKeys = {}
        for _, key in ipairs({ "Q", "R", "E", "left", "right", "up", "down", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" }) do
          ternKeys[mainMod .. " + " .. key] = true
        end

        local function isTern(window)
          local class = window and string.lower(window.class) or ""
          return class == "tern" or class == "so.stencil.tern"
        end

        for _, direction in ipairs({ "left", "right", "up", "down" }) do
          ternKeys[mainMod .. " + SHIFT + " .. direction] = true
        end

        for number = 0, 9 do
          ternKeys[mainMod .. " + SHIFT + " .. tostring(number)] = true
        end

        local ternMode = false
        local function setTernMode(enabled)
          ternMode = enabled
          hl.dispatch(hl.dsp.submap(enabled and "tern" or "reset"))
        end

        local function registerBindings(inTern)
          for _, binding in ipairs(desktopBindings) do
            if not inTern or not ternKeys[binding.keys] then
              hl.bind(binding.keys, binding.dispatcher, binding.options)
            end
          end
          hl.bind(mainMod .. " + SHIFT + Escape", function()
            setTernMode(not ternMode and isTern(hl.get_active_window()))
          end)
        end

        registerBindings(false)
        hl.define_submap("tern", function()
          registerBindings(true)
        end)
        hl.on("window.active", function(window)
          setTernMode(isTern(window))
        end)
        -- Reconcile an already-focused Tern after a config reload too.
        setTernMode(isTern(hl.get_active_window()))

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

      toLua = lib.generators.toLua { };
      renderArgs = value: if builtins.isAttrs value && value ? _args
        then lib.concatMapStringsSep ", " toLua value._args else toLua value;
      calls = settings
        |> lib.mapAttrsToList (name: value:
          value
          |> lib.toList
          |> lib.concatMapStringsSep "\n" (argument: "hl.${name}(${renderArgs argument})")
        )
        |> lib.concatStringsSep "\n";
    in {
      packages = [ osConfig.programs.hyprland.package pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-hyprland ];
      environment.sessionVariables.NIX_XDG_DESKTOP_PORTAL_DIR =
        "/etc/profiles/per-user/${config.user}/share/xdg-desktop-portal/portals";
      xdg.config.files."hypr/.luarc.json".source = (pkgs.formats.json { }).generate "hypr-luarc.json" {
        diagnostics.globals = [ "hl" ];
        workspace.library = [ "${osConfig.programs.hyprland.package}/share/hypr/stubs" ];
      };
      xdg.config.files."hypr/hyprland.lua".text = calls + ''
        hl.on("hyprland.start", function()
          hl.exec_cmd("${pkgs.dbus}/bin/dbus-update-activation-environment --systemd DISPLAY HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE && systemctl --user stop hyprland-session.target && systemctl --user start hyprland-session.target")
        end)
        hl.on("hyprland.shutdown", function()
          os.execute("systemctl --user stop hyprland-session.target && sleep 0.1")
        end)
      '' + extraConfig;
      systemd.targets = {
        hyprland-session = {
          description = "Hyprland compositor session";
          after = [ "graphical-session-pre.target" ];
          wants = [ "graphical-session-pre.target" ];
          bindsTo = [ "graphical-session.target" ];
          unitConfig.PropagatesStopTo = [ "graphical-session.target" ];
        };
        tray = {
          description = "System tray";
          requires = [ "graphical-session-pre.target" ];
        };
      };
    };
}
