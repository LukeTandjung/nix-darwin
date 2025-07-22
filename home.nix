{ config, pkgs, lib, inputs, ... }:

{
  home.username = "luketandjung";
  home.homeDirectory = "/Users/luketandjung"; # Standard macOS home directory path
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;
  programs.zsh.enable = true;

  # Zed Editor Configuration
  programs.zed-editor = {
    enable = true;
    extraPackages = [ pkgs.nodejs_22 ]; # Ensure nodejs_22 is available on macOS
    userSettings = {
      node = {
        path     = lib.getExe pkgs.nodejs_22;
        npm_path = lib.getExe' pkgs.nodejs_22 "npm";
      };
      languages = {
        Python = {
          language_servers = [ "pyright" "ruff" ];
        };
      };
      direnv = { enable = true; };
      vim_mode = true;
      show_edit_predictions = false;
      buffer_font_size = lib.mkForce 14.0;
      ui_font_size = lib.mkForce 14.0;
    };
  };

  # Direnv Configuration
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # --- Package Management ---
  home.packages = with pkgs; [
    # Note: Excluded Wayland-specific, NixOS-specific, and audio visualizers.
    # Find macOS-native alternatives if needed.
  ];

  # --- MIGRATING YOUR RICE ---
  # Use home.file.source to manage raw configuration files.
  # Ensure these paths exist in your repo (e.g., ~/nix-darwin)

  # Aerospace Configuration
  # home.file.".config/aerospace/aerospace.toml".source = ./config/aerospace/aerospace.toml;

  # Sketchybar Configuration
  # home.file.".config/sketchybar/sketchybarrc".source = ./config/sketchybar/sketchybarrc;
  # home.file.".config/sketchybar/icons".source = ./config/sketchybar/icons; # Example for other files
}
