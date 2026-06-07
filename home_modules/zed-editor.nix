{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  # Zed now rejects the Stylix-generated theme when tinted-zed receives an
  # unspecified scheme variant. Our inline Kanagawa scheme is dark, so make that
  # explicit for this target while keeping Stylix in charge of colors/fonts.
  stylix.targets.zed.colors.override.scheme-variant = "dark";

  programs.zed-editor = {
    enable = true;
    package = pkgs.zed-editor;
    extraPackages = [ pkgs.nodejs_22 ]; # Ensure nodejs_22 is available on macOS
    extensions = [
      "nix"
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
      buffer_font_size = lib.mkForce 14.0;
      ui_font_size = lib.mkForce 14.0;
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
}
