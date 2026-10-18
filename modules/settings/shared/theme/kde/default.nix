{ lib, ... }:
{
  # Color roles adapted from Stylix's KDE theme (MIT).
  modules.hjem.theme = { pkgs, theme, ... }:
    let
      ini = pkgs.formats.ini { };
      rgb = lib.mapAttrs (_: values: lib.concatMapStringsSep "," toString values) theme.rgb;
      foreground = color: lib.genAttrs [
        "ForegroundActive" "ForegroundInactive" "ForegroundLink"
        "ForegroundNormal" "ForegroundVisited"
      ] (_: color);
      commonColors = foreground rgb.base05 // {
        BackgroundAlternate = rgb.base01;
        BackgroundNormal = rgb.base00;
        DecorationFocus = rgb.base0D;
        DecorationHover = rgb.base0D;
        ForegroundNegative = rgb.base08;
        ForegroundNeutral = rgb.base0D;
        ForegroundPositive = rgb.base0B;
      };
      effects = {
        ColorAmount = 0;
        ColorEffect = 0;
        ContrastAmount = "0.500000";
        ContrastEffect = 1;
        IntensityAmount = 0;
        IntensityEffect = 0;
      };
      colors = lib.genAttrs [
        "Colors:Button" "Colors:Complementary" "Colors:Tooltip" "Colors:View" "Colors:Window"
      ] (_: commonColors) // {
        "ColorEffects:Disabled" = effects;
        "ColorEffects:Inactive" = effects;
        "Colors:Selection" = commonColors // foreground rgb.base00 // {
          BackgroundAlternate = rgb.base0D;
          BackgroundNormal = rgb.base0D;
        };
        General = { ColorScheme = "Kanagawa"; Name = "Kanagawa"; };
        WM = {
          activeBackground = rgb.base00;
          activeBlend = rgb.base0A;
          activeForeground = rgb.base05;
          inactiveBackground = rgb.base00;
          inactiveBlend = rgb.base03;
          inactiveForeground = rgb.base05;
        };
      };
      font = "${theme.font},${toString theme.fontSize},-1,5,50,0,0,0,0,0";
      globals = ini.generate "kdeglobals" {
        General = lib.genAttrs [
          "desktopFont[$i]" "fixed[$i]" "font[$i]" "menuFont[$i]"
          "smallestReadableFont[$i]" "taskbarFont[$i]" "toolBarFont[$i]"
        ] (_: font);
        KDE."LookAndFeelPackage[$i]" = "kanagawa";
        UiSettings.ColorScheme = "Kanagawa";
        WM."activeFont[$i]" = font;
      };
      kdeConfig = pkgs.runCommand "kanagawa-kde-config" { } ''
        mkdir "$out"
        cp ${globals} "$out/kdeglobals"
        cp ${./kded5rc} "$out/kded5rc"
        printf '[Mouse]\ncursorSize[$i]=24\ncursorTheme[$i]=Adwaita\n' > "$out/kcminputrc"
      '';
    in lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
      environment.sessionVariables.XDG_CONFIG_DIRS = "${kdeConfig}\${XDG_CONFIG_DIRS:+:$XDG_CONFIG_DIRS}";
      xdg.data.files."color-schemes/Kanagawa.colors".source = ini.generate "Kanagawa.colors" colors;
    };
}
