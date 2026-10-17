{ ... }:
{
  modules.hjem.zed-editor = { pkgs, lib, theme, ... }:
    let
      cfg = {
        extensions = [
          "nix"
          "deno"
          "typst"
          "latex"
          "opencode"
        ];
        userSettings = {
          node = {
            path = lib.getExe pkgs.nodejs_22;
            npm_path = lib.getExe' pkgs.nodejs_22 "npm";
          };
          tab_size = 2;
          lsp = {
            nix = {
              binary = {
                path_lookup = true;
              };
            };
            tinymist = {
              initialization_options = {
                exportPdf = "onSave";
                outputPath = "$root/$name";
              };
            };
          };
          languages = {
            Python = {
              language_servers = [
                "pyright"
                "ruff"
              ];
            };
            PHP = {
              format_on_save = "off";
            };
          };
          agent_servers = {
            "Kimi CLI" = {
              command = "kimi";
              args = [ "--acp" ];
              env = { };
            };
          };
          direnv = {
            enable = true;
          };
          helix_mode = true;
          show_edit_predictions = false;
          buffer_font_size = 14.0;
          ui_font_size = 14.0;
        };
        userKeymaps = [
          {
            context = "Workspace";
            bindings = {
              alt-h = "workspace::ActivatePaneLeft";
              alt-l = "workspace::ActivatePaneRight";
              alt-k = "workspace::ActivatePaneUp";
              alt-j = "workspace::ActivatePaneDown";
            };
          }
        ];
      };
      settings = (pkgs.formats.json { }).generate "zed-settings.json" (cfg.userSettings // {
        buffer_font_family = theme.font;
        ui_font_family = theme.font;
        theme = "Base16 Kanagawa";
        auto_install_extensions = lib.genAttrs cfg.extensions (_: true);
      });
      keymap = (pkgs.formats.json { }).generate "zed-keymap.json" cfg.userKeymaps;
      zed = pkgs.symlinkJoin {
        name = "zed-editor-wrapped-${pkgs.zed-editor.version}";
        paths = [ pkgs.zed-editor ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram "$out/bin/${pkgs.zed-editor.meta.mainProgram or "zeditor"}" --suffix PATH : ${lib.makeBinPath [ pkgs.nodejs_22 ]}
        '';
        inherit (pkgs.zed-editor) meta;
      };
    in {
      packages = [ zed ];
      xdg.config.files = {
        "zed/themes/kanagawa.json".text = theme.render ./theme.mustache { };
        # Replace mutable app settings through Hjem, retaining collision backups.
        "zed/settings.json" = { source = settings; clobber = true; };
        "zed/keymap.json" = { source = keymap; clobber = true; };
      };
    };
}
