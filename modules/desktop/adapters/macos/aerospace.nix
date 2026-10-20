{ inputs, ... }:
{
  modules.hjem.aerospace =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      aerospace = lib.getExe pkgs.aerospace;
      focusMode = pkgs.writeShellScript "aerospace-focus-mode" ''
        set -eu
        app="$(${aerospace} list-windows --focused --format '%{app-bundle-id}')"
        mode=main
        if [ "$app" = so.stencil.tern ]; then
          mode=tern
          if [ "''${1:-}" = toggle ] && [ "$(${aerospace} list-modes --current)" = tern ]; then
            mode=main
          fi
        fi
        ${aerospace} mode "$mode"
      '';
      ternSearch = pkgs.writeShellScript "tern-search" ''
        # ctl needs the daemon endpoint when invoked outside a Tern shell.
        export TERN_PANE_SOCKET="$HOME/Library/Application Support/Tern/daemon.sock"
        exec ${lib.getExe config.programs.tern.package} ctl plugins run palette
      '';
      closeWindow = pkgs.writeShellScript "aerospace-close-window" ''
        set -eu
        app="$(${aerospace} list-windows --focused --format '%{app-bundle-id}')"
        # Never let the ordinary close shortcut destroy a Tern window, even
        # if a focus change briefly leaves AeroSpace in main mode.
        if [ "$app" = so.stencil.tern ] && [ "''${1:-}" != whole-window ]; then
          exit 0
        fi
        if [ "$app" = org.keepassxc.keepassxc ]; then
          ${aerospace} close
        else
          ${aerospace} close --quit-if-last-window
        fi
      '';
      desktopBindings = {
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
        cmd-shift-1 = [
          "move-node-to-workspace 1"
          "workspace 1"
        ];
        cmd-shift-2 = [
          "move-node-to-workspace 2"
          "workspace 2"
        ];
        cmd-shift-3 = [
          "move-node-to-workspace 3"
          "workspace 3"
        ];
        cmd-shift-4 = [
          "move-node-to-workspace 4"
          "workspace 4"
        ];
        cmd-shift-5 = [
          "move-node-to-workspace 5"
          "workspace 5"
        ];

        # Open Tern (cmd + q)
        cmd-q = "exec-and-forget open -a Tern";

        # AeroSpace owns the launcher shortcut so Tern can override it.
        cmd-r = "exec-and-forget open -a Raycast";

        # Open Finder (cmd + e); Tern mode uses its built-in Files pane.
        cmd-e = "exec-and-forget open -a Finder";

        # Keep KeePassXC alive; preserve quit-on-last-window for other apps.
        cmd-x = "exec-and-forget ${closeWindow}";
        cmd-shift-esc = "exec-and-forget ${focusMode} toggle";
      };
    in lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      packages = [ pkgs.aerospace ];
      files = {
        ".aerospace.toml".source = (pkgs.formats.toml { }).generate "aerospace.toml" {
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
              top = [
                {
                  monitor = {
                    "MSI G24C4" = 32;
                  };
                }
                {
                  monitor = {
                    "U34E2M" = 32;
                  };
                }
                {
                  monitor = {
                    "XREAL One Pro" = 32;
                  };
                }
                16
              ];
              right = 16;
            };
          };

          # NOTE: The following yabai features have no AeroSpace equivalent:
          #   - focus_follows_mouse = "autoraise"
          #   - window_opacity (active/normal)
          #   - menubar_opacity = 0.0

          persistent-workspaces = [
            "1"
            "2"
            "3"
            "4"
            "5"
          ];

          after-startup-command = [ "exec-and-forget ${focusMode}" ];
          on-focus-changed = [ "exec-and-forget ${focusMode}" ];
          mode.main.binding = desktopBindings;
          mode.tern.binding = (builtins.removeAttrs desktopBindings [
            "cmd-q" "cmd-r" "cmd-e" "cmd-x"
            "cmd-left" "cmd-right" "cmd-up" "cmd-down"
            "cmd-shift-left" "cmd-shift-right" "cmd-shift-up" "cmd-shift-down"
            "cmd-1" "cmd-2" "cmd-3" "cmd-4" "cmd-5"
            "cmd-6" "cmd-7" "cmd-8" "cmd-9" "cmd-0"
            "cmd-shift-1" "cmd-shift-2" "cmd-shift-3" "cmd-shift-4" "cmd-shift-5"
            "cmd-shift-6" "cmd-shift-7" "cmd-shift-8" "cmd-shift-9" "cmd-shift-0"
          ]) // {
            # Only Tern mode reserves Shift+X for closing the entire window.
            cmd-shift-x = "exec-and-forget ${closeWindow} whole-window";
            # Tern search replaces the desktop's Raycast launcher.
            cmd-r = "exec-and-forget ${ternSearch}";
          };
        };
      };
    };

  modules.darwin.aerospace = { pkgs, ... }: {
    launchd.user.agents.aerospace.serviceConfig = {
      Label = "org.hjem.aerospace";
      Program = "${pkgs.aerospace}/Applications/AeroSpace.app/Contents/MacOS/AeroSpace";
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/aerospace.log";
      StandardErrorPath = "/tmp/aerospace.err.log";
    };
  };
}
