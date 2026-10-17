{ lib, ... }:
let
  palette = {
    base00 = "1F1F28"; base01 = "16161D"; base02 = "223249"; base03 = "54546D";
    base04 = "727169"; base05 = "DCD7BA"; base06 = "C8C093"; base07 = "717C7C";
    base08 = "C34043"; base09 = "FFA066"; base0A = "C0A36E"; base0B = "76946A";
    base0C = "6A9589"; base0D = "7E9CD8"; base0E = "957FB8"; base0F = "D27E99";
  };
  terminalColors = with palette; [ base00 base08 base0B base0A base0D base0E base0C base05 base03 base08 base0B base0A base0D base0E base0C base07 ];
  digits = builtins.listToAttrs (builtins.genList (n: {
    name = builtins.substring n 1 "0123456789abcdef";
    value = n;
  }) 16);
  component = hex: offset:
    digits.${lib.toLower (builtins.substring offset 1 hex)} * 16
    + digits.${lib.toLower (builtins.substring (offset + 1) 1 hex)};
  tokens = {
    scheme-name = "Kanagawa";
    scheme-author = "Tommaso Laurenzi (https://github.com/rebelot)";
    scheme-description = "Kanagawa";
    scheme-system = "base16";
    scheme-variant = "dark";
  } // lib.foldlAttrs (acc: name: value: acc // {
    "${name}-hex" = value;
    "${name}-rgb-r" = toString (component value 0);
    "${name}-rgb-g" = toString (component value 2);
    "${name}-rgb-b" = toString (component value 4);
    "${name}-dec-r" = toString (component value 0 / 256.0);
    "${name}-dec-g" = toString (component value 2 / 256.0);
    "${name}-dec-b" = toString (component value 4 / 256.0);
  }) { } palette;
  forPkgs = pkgs:
    let
      mac = pkgs.stdenv.hostPlatform.isDarwin;
      font = if mac then "JetBrains Mono" else "IBM Plex Mono";
      fontSize = if mac then 14 else 12;
      render = path: extra:
        let values = tokens // extra;
        in lib.replaceStrings
          (map (name: "{{${name}}}") (builtins.attrNames values))
          (builtins.attrValues values)
          (builtins.readFile path);
    in {
      inherit palette terminalColors font fontSize render;
      colors = lib.mapAttrs (_: value: "#${value}") palette;
      fontPackage = if mac then pkgs.jetbrains-mono else pkgs.ibm-plex;
      emojiFont = if mac then "JetBrains Mono NF" else "IBM Plex Mono";
      fontPackages = if mac then [ pkgs.jetbrains-mono pkgs.nerd-fonts.jetbrains-mono ] else [ pkgs.ibm-plex ];
    };
in
{
  options.styling.forPkgs = lib.mkOption {
    type = lib.types.functionTo lib.types.raw;
    readOnly = true;
    default = forPkgs;
    description = "Shared Kanagawa palette and platform-specific typography for owned renderers.";
  };

  config.modules.nixos.theme = { pkgs, ... }: {
    console.colors = terminalColors;
    fonts = {
      packages = (forPkgs pkgs).fontPackages;
      fontconfig = {
        enable = true;
        defaultFonts = {
          monospace = [ "IBM Plex Mono" ];
          sansSerif = [ "IBM Plex Mono" ];
          serif = [ "IBM Plex Mono" ];
          emoji = [ "IBM Plex Mono" ];
        };
      };
    };
    programs.dconf.enable = true;
    qt = { enable = true; platformTheme = "qt5ct"; style = "kvantum"; };
  };

  config.modules.darwin.theme = { pkgs, ... }: {
    fonts.packages = (forPkgs pkgs).fontPackages;
    services.jankyborders = {
      active_color = "0xff${palette.base0D}";
      inactive_color = "0xff${palette.base03}";
    };
  };

  config.modules.hjem.theme = { config, pkgs, ... }:
    let
      theme = forPkgs pkgs;
      linux = pkgs.stdenv.hostPlatform.isLinux;
      ini = pkgs.formats.ini { };
      kdeConfig = pkgs.runCommand "kanagawa-kde-config" { } ''
        mkdir "$out"
        cp ${pkgs.writeText "kdeglobals" (theme.render ./kdeglobals.mustache {
          font-family = theme.font;
          font-size = toString theme.fontSize;
        })} "$out/kdeglobals"
        cp ${./kded5rc} "$out/kded5rc"
        printf '[Mouse]\ncursorSize[$i]=24\ncursorTheme[$i]=Adwaita\n' > "$out/kcminputrc"
      '';
      gtkSettings.Settings = {
        gtk-theme-name = "adw-gtk3";
        gtk-font-name = "${theme.font} ${toString theme.fontSize}";
      } // lib.optionalAttrs linux {
        gtk-cursor-theme-name = "Adwaita";
        gtk-cursor-theme-size = 24;
      };
    in {
      packages = theme.fontPackages ++ [ pkgs.adw-gtk3 ]
        ++ lib.optionals linux [ pkgs.adwaita-icon-theme pkgs.libsForQt5.qt5ct pkgs.kdePackages.qt6ct pkgs.libsForQt5.qtstyleplugin-kvantum pkgs.kdePackages.qtstyleplugin-kvantum ];
      environment.sessionVariables = {
        GTK2_RC_FILES = "${config.directory}/.gtkrc-2.0";
      } // lib.optionalAttrs linux {
        QT_QPA_PLATFORMTHEME = "qt5ct";
        QT_STYLE_OVERRIDE = "kvantum";
        XCURSOR_THEME = "Adwaita";
        XCURSOR_SIZE = 24;
        XDG_CONFIG_DIRS = "${kdeConfig}\${XDG_CONFIG_DIRS:+:$XDG_CONFIG_DIRS}";
      };
      files = {
        ".themes/adw-gtk3".source = "${pkgs.adw-gtk3}/share/themes/adw-gtk3";
        ".gtkrc-2.0".text = ''
          gtk-theme-name="adw-gtk3"
          gtk-font-name="${theme.font} ${toString theme.fontSize}"
        '';
        ".Xresources".text = ''
          *.faceName: ${theme.font}
          *.faceSize: ${toString theme.fontSize}
          *.renderFont: true
          *background: #${palette.base00}
          *foreground: #${palette.base05}
          *cursorColor: #${palette.base05}
          Sxiv.background: #${palette.base04}
          Sxiv.foreground: #${palette.base01}
          Sxiv.font: ${theme.font}-${toString theme.fontSize}
        '' + lib.concatImapStringsSep "\n" (i: color: "*color${toString (i - 1)}: #${color}")
          (lib.take 8 terminalColors ++ [ palette.base02 ] ++ lib.drop 9 terminalColors
            ++ (with palette; [ base09 base0F base01 base02 base04 base06 ]))
          + lib.optionalString linux "\nXcursor.size: 24\nXcursor.theme: Adwaita\n";
      } // lib.optionalAttrs linux {
        ".icons/Adwaita".source = "${pkgs.adwaita-icon-theme}/share/icons/Adwaita";
        ".icons/default/index.theme".text = "[Icon Theme]\nInherits=Adwaita\n";
      };
      xdg.data.files = lib.genAttrs
        (map (version: "${version}/styles/kanagawa.xml") [ "gedit" "gtksourceview-2.0" "gtksourceview-3.0" "gtksourceview-4" "gtksourceview-5" ])
        (_: { text = theme.render ./gtksourceview.xml.mustache { }; })
        // lib.optionalAttrs linux {
          "color-schemes/Kanagawa.colors".text = theme.render ./kde.colors.mustache { };
          "plasma/look-and-feel/kanagawa".source = ./kde-look-and-feel;
          "icons/Adwaita".source = "${pkgs.adwaita-icon-theme}/share/icons/Adwaita";
          "icons/default/index.theme".text = "[Icon Theme]\nInherits=Adwaita\n";
        };
      activationScripts = lib.optionalAttrs linux {
        gtk-settings = {
          "org/gnome/desktop/interface/color-scheme" = "default";
          "org/gnome/desktop/interface/gtk-theme" = "adw-gtk3";
          "org/gnome/desktop/interface/font-name" = "${theme.font} ${toString theme.fontSize}";
          "org/gnome/desktop/interface/document-font-name" = "${theme.font} 11";
          "org/gnome/desktop/interface/monospace-font-name" = "${theme.font} ${toString theme.fontSize}";
          "org/gnome/desktop/interface/cursor-theme" = "Adwaita";
          "org/gnome/desktop/interface/cursor-size" = 24;
          "org/gnome/TextEditor/style-scheme" = "kanagawa";
          "org/gnome/eog/view/background-color" = theme.colors.base00;
        }
        |> lib.mapAttrsToList (key: value:
          "${pkgs.dconf}/bin/dconf write /${key} ${lib.escapeShellArg (if builtins.isString value then "'${value}'" else toString value)}"
        )
        |> lib.concatStringsSep "\n";
      };
      xdg.config.files = {
        "gtk-3.0/settings.ini".source = ini.generate "gtk3-settings.ini" gtkSettings;
        "gtk-4.0/settings.ini".source = ini.generate "gtk4-settings.ini" gtkSettings;
        "gtk-3.0/gtk.css".text = theme.render ./gtk.css.mustache { };
        "gtk-4.0/gtk.css".text = theme.render ./gtk.css.mustache { };
      } // lib.optionalAttrs linux {
        "fontconfig/conf.d/10-hjem-fonts.conf".text = ''
          <?xml version="1.0"?>
          <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
          <fontconfig>
            <dir>${config.directory}/.nix-profile/share/fonts</dir>
            <dir>/etc/profiles/per-user/${config.user}/share/fonts</dir>
          </fontconfig>
        '';
        "fontconfig/conf.d/52-hjem-default-fonts.conf".text = ''
          <?xml version="1.0"?>
          <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
          <fontconfig>
            ${lib.concatMapStrings (family: "<alias binding=\"same\"><family>${family}</family><prefer><family>${theme.font}</family></prefer></alias>") [ "monospace" "sans-serif" "serif" "emoji" ]}
          </fontconfig>
        '';
        "Kvantum/kvantum.kvconfig".text = "[General]\ntheme=Base16Kvantum\n";
        "Kvantum/Base16Kvantum/Base16Kvantum.kvconfig".text = theme.render ./kvconfig.mustache { };
        "Kvantum/Base16Kvantum/Base16Kvantum.svg".text = theme.render ./kvantum.svg.mustache { };
        "qt5ct/qt5ct.conf".source = ini.generate "qt5ct.conf" {
          Appearance = { style = "kvantum"; custom_palette = true; standard_dialogs = "default"; icon_theme = "Adwaita"; };
          Fonts = { fixed = ''"${theme.font},${toString theme.fontSize}"''; general = ''"${theme.font},${toString theme.fontSize}"''; };
        };
        "qt6ct/qt6ct.conf".source = config.xdg.config.files."qt5ct/qt5ct.conf".source;
      };
    };
}
