{ lib, ... }:
{
  # GTK color roles adapted from Stylix (MIT).
  modules.hjem.theme = { theme, ... }:
    let
      inherit (theme) colors;
      roles = lib.concatMapAttrs (role: color: {
        "${role}_color" = color;
        "${role}_bg_color" = color;
        "${role}_fg_color" = colors.base00;
      }) {
        accent = colors.base0D;
        destructive = colors.base08;
        success = colors.base0B;
        warning = colors.base0E;
        error = colors.base08;
      };
      shades = lib.concatMapAttrs (family: color:
        lib.genAttrs (map (index: "${family}_${toString index}") (lib.range 1 5)) (_: color)
      ) {
        blue = colors.base0D;
        green = colors.base0B;
        yellow = colors.base0A;
        orange = colors.base09;
        red = colors.base08;
        purple = colors.base0E;
        brown = colors.base0F;
        light = colors.base05;
        dark = colors.base05;
      };
      shade = "rgba(0, 0, 0, 0.07)";
      # Preserve the existing normalized component values during this refactor.
      border = lib.concatMapStringsSep ", " (value: toString (value / 256.0)) theme.rgb.base01;
      surfaces = {
        window_bg_color = colors.base00;
        window_fg_color = colors.base05;
        view_bg_color = colors.base00;
        view_fg_color = colors.base05;
        headerbar_bg_color = colors.base01;
        headerbar_fg_color = colors.base05;
        headerbar_border_color = "rgba(${border}, 0.7)";
        headerbar_backdrop_color = "@window_bg_color";
        headerbar_shade_color = shade;
        headerbar_darker_shade_color = shade;
        sidebar_bg_color = colors.base01;
        sidebar_fg_color = colors.base05;
        sidebar_backdrop_color = "@window_bg_color";
        sidebar_shade_color = shade;
        secondary_sidebar_bg_color = "@sidebar_bg_color";
        secondary_sidebar_fg_color = "@sidebar_fg_color";
        secondary_sidebar_backdrop_color = "@sidebar_backdrop_color";
        secondary_sidebar_shade_color = "@sidebar_shade_color";
        card_bg_color = colors.base01;
        card_fg_color = colors.base05;
        card_shade_color = shade;
        dialog_bg_color = colors.base01;
        dialog_fg_color = colors.base05;
        popover_bg_color = colors.base01;
        popover_fg_color = colors.base05;
        popover_shade_color = shade;
        shade_color = shade;
        scrollbar_outline_color = colors.base02;
      };
      css = roles // surfaces // shades
        |> lib.mapAttrsToList (name: value: "@define-color ${name} ${value};")
        |> lib.concatStringsSep "\n";
    in {
      xdg.config.files = lib.genAttrs [ "gtk-3.0/gtk.css" "gtk-4.0/gtk.css" ] (_: {
        text = css + "\n";
      });
    };
}
