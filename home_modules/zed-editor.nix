{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  programs.zed-editor = {
    enable = true;
    package = pkgs.zed-editor;
    extraPackages = [ pkgs.nodejs_22 ]; # Ensure nodejs_22 is available on macOS
    userSettings = {
      node = {
        path = lib.getExe pkgs.nodejs_22;
        npm_path = lib.getExe' pkgs.nodejs_22 "npm";
      };
      tab_size = 2;
      languages = {
        Python = {
          language_servers = [
            "pyright"
            "ruff"
          ];
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
  };
}
