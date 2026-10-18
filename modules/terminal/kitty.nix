{ lib, ... }:
{
  # Color mapping: Tinted Theming/tinted-kitty (MIT).
  # Palette: Kanagawa by Tommaso Laurenzi (https://github.com/rebelot).
  modules.hjem.kitty = { pkgs, theme, ... }:
    let
      inherit (theme) colors;
      # Kitty uses base02 for bright black; the console palette uses base03.
      terminalColors = with theme.palette;
        lib.take 8 theme.terminalColors ++ [ base02 ] ++ lib.drop 9 theme.terminalColors
        ++ [ base09 base0F base01 base02 base04 base06 ];
      settings = {
        font_family = theme.font;
        font_size = theme.fontSize;
        macos_option_as_alt = "yes";
        enabled_layouts = "horizontal";
        # Files are Nix-managed; avoid recursively watching store paths.
        auto_reload_config = -1;
        background_opacity = 1;
        background = colors.base00;
        foreground = colors.base05;
        selection_background = colors.base03;
        selection_foreground = colors.base05;
        cursor = colors.base05;
        cursor_text_color = colors.base00;
        url_color = colors.base04;
        active_border_color = colors.base03;
        inactive_border_color = colors.base01;
        wayland_titlebar_color = colors.base00;
        macos_titlebar_color = colors.base00;
        active_tab_background = colors.base00;
        active_tab_foreground = colors.base05;
        inactive_tab_background = colors.base01;
        inactive_tab_foreground = colors.base04;
        tab_bar_background = colors.base01;
      } // (lib.imap0 (index: color: {
        name = "color${toString index}";
        value = "#${color}";
      }) terminalColors |> builtins.listToAttrs);
    in {
      packages = [ pkgs.kitty ];
      xdg.config.files."kitty/kitty.conf".text = lib.generators.toKeyValue {
        mkKeyValue = lib.generators.mkKeyValueDefault { } " ";
      } settings;
    };
}
