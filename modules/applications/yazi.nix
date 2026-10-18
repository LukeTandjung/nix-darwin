{ inputs, ... }:
{
  # Syntax mapping adapted from sharkdp/bat's base16.tmTheme.
  # Copyright (c) 2018-2023 bat-developers; original scheme attribution retained.
  # UI color mapping adapted from Stylix (MIT).
  modules.hjem.yazi =
    {
      config,
      pkgs,
      theme,
      lib,
      ...
    }:
    let
      colors = theme.colors;
      syntaxTheme = (pkgs.formats.plist { }).generate "kanagawa.tmTheme" {
        author = "Template: Chris Kempson, Scheme: Mitchell Kember";
        name = "Base16 Stylix";
        colorSpaceName = "sRGB";
        settings = [
          {
            settings = {
              background = colors.base00;
              caret = colors.base05;
              foreground = colors.base05;
              invisibles = colors.base03;
              lineHighlight = colors.base03;
              selection = colors.base02;
              gutter = colors.base01;
              gutterForeground = colors.base03;
            };
          }
          {
            name = "Text";
            scope = "variable.parameter.function";
            settings = { foreground = colors.base05; };
          }
          {
            name = "Comments";
            scope = "comment, punctuation.definition.comment";
            settings = { foreground = colors.base03; };
          }
          {
            name = "Punctuation";
            scope = "punctuation.definition.string, punctuation.definition.variable, punctuation.definition.string, punctuation.definition.parameters, punctuation.definition.string, punctuation.definition.array";
            settings = { foreground = colors.base05; };
          }
          { name = "Delimiters"; scope = "none"; settings = { foreground = colors.base05; }; }
          { name = "Operators"; scope = "keyword.operator"; settings = { foreground = colors.base05; }; }
          { name = "Keywords"; scope = "keyword"; settings = { foreground = colors.base0E; }; }
          { name = "Variables"; scope = "variable"; settings = { foreground = colors.base05; }; }
          {
            name = "Functions";
            scope = "entity.name.function, meta.require, support.function.any-method";
            settings = { foreground = colors.base0D; };
          }
          { name = "Labels"; scope = "entity.name.label"; settings = { foreground = colors.base0F; }; }
          {
            name = "Classes";
            scope = "support.class, entity.name.class, entity.name.type.class, entity.name";
            settings = { foreground = colors.base0A; };
          }
          { name = "Classes"; scope = "meta.class"; settings = { foreground = colors.base07; }; }
          {
            name = "Methods";
            scope = "keyword.other.special-method";
            settings = { foreground = colors.base0D; };
          }
          { name = "Storage"; scope = "storage"; settings = { foreground = colors.base0E; }; }
          { name = "Support"; scope = "support.function"; settings = { foreground = colors.base0C; }; }
          {
            name = "Strings, Inherited Class";
            scope = "string, constant.other.symbol, entity.other.inherited-class";
            settings = { foreground = colors.base0B; };
          }
          { name = "Integers"; scope = "constant.numeric"; settings = { foreground = colors.base09; }; }
          { name = "Floats"; scope = "none"; settings = { foreground = colors.base09; }; }
          { name = "Boolean"; scope = "none"; settings = { foreground = colors.base09; }; }
          { name = "Constants"; scope = "constant"; settings = { foreground = colors.base09; }; }
          { name = "Tags"; scope = "entity.name.tag"; settings = { foreground = colors.base08; }; }
          {
            name = "Attributes";
            scope = "entity.other.attribute-name";
            settings = { foreground = colors.base09; };
          }
          {
            name = "Attribute IDs";
            scope = "entity.other.attribute-name.id, punctuation.definition.entity";
            settings = { foreground = colors.base0D; };
          }
          { name = "Selector"; scope = "meta.selector"; settings = { foreground = colors.base0E; }; }
          { name = "Values"; scope = "none"; settings = { foreground = colors.base09; }; }
          {
            name = "Headings";
            scope = "markup.heading, punctuation.definition.heading, entity.name.section";
            settings = { fontStyle = ""; foreground = colors.base0D; };
          }
          { name = "Units"; scope = "keyword.other.unit"; settings = { foreground = colors.base09; }; }
          {
            name = "Bold";
            scope = "markup.bold, punctuation.definition.bold";
            settings = { fontStyle = "bold"; foreground = colors.base0A; };
          }
          {
            name = "Italic";
            scope = "markup.italic, punctuation.definition.italic";
            settings = { fontStyle = "italic"; foreground = colors.base0E; };
          }
          { name = "Code"; scope = "markup.raw.inline"; settings = { foreground = colors.base0B; }; }
          {
            name = "Link Text";
            scope = "string.other.link, punctuation.definition.string.end.markdown, punctuation.definition.string.begin.markdown";
            settings = { foreground = colors.base08; };
          }
          { name = "Link Url"; scope = "meta.link"; settings = { foreground = colors.base09; }; }
          { name = "Quotes"; scope = "markup.quote"; settings = { foreground = colors.base09; }; }
          {
            name = "Separator";
            scope = "meta.separator";
            settings = { background = colors.base02; foreground = colors.base05; };
          }
          { name = "Inserted"; scope = "markup.inserted"; settings = { foreground = colors.base0B; }; }
          { name = "Deleted"; scope = "markup.deleted"; settings = { foreground = colors.base08; }; }
          { name = "Changed"; scope = "markup.changed"; settings = { foreground = colors.base0E; }; }
          { name = "Colors"; scope = "constant.other.color"; settings = { foreground = colors.base0C; }; }
          {
            name = "Regular Expressions";
            scope = "string.regexp";
            settings = { foreground = colors.base0C; };
          }
          {
            name = "Escape Characters";
            scope = "constant.character.escape";
            settings = { foreground = colors.base0C; };
          }
          {
            name = "Embedded";
            scope = "punctuation.section.embedded, variable.interpolation";
            settings = { foreground = colors.base0E; };
          }
          {
            name = "Illegal";
            scope = "invalid.illegal";
            settings = { background = colors.base08; foreground = colors.base07; };
          }
          {
            name = "Broken";
            scope = "invalid.broken";
            settings = { background = colors.base09; foreground = colors.base00; };
          }
          {
            name = "Deprecated";
            scope = "invalid.deprecated";
            settings = { background = colors.base0F; foreground = colors.base07; };
          }
          {
            name = "Unimplemented";
            scope = "invalid.unimplemented";
            settings = { background = colors.base03; foreground = colors.base07; };
          }
        ];
        uuid = "uuid";
      };
    in {
      packages = [ pkgs.yazi ];
      zshInit = ''
        function yy() {
          local tmp="$(mktemp -t yazi-cwd.XXXXXX)" cwd
          yazi "$@" --cwd-file="$tmp"
          IFS= read -r cwd < "$tmp"
          [[ -n "$cwd" && "$cwd" != "$PWD" ]] && builtin cd -- "$cwd"
          rm -f -- "$tmp"
        }
      '';
      xdg.config.files = {
        "yazi/theme.toml".source =
          (pkgs.formats.toml { }).generate "yazi-theme.toml" {
            completion = {
              active = { bg = colors.base03; fg = colors.base0E; };
              border = { fg = colors.base0D; };
              inactive = { fg = colors.base05; };
            };
            filetype = {
              rules = [
                { fg = colors.base0C; mime = "image/*"; }
                { fg = colors.base0A; mime = "video/*"; }
                { fg = colors.base0A; mime = "audio/*"; }
                { fg = colors.base0E; mime = "application/zip"; }
                { fg = colors.base0E; mime = "application/gzip"; }
                { fg = colors.base0E; mime = "application/tar"; }
                { fg = colors.base0E; mime = "application/bzip"; }
                { fg = colors.base0E; mime = "application/bzip2"; }
                { fg = colors.base0E; mime = "application/7z-compressed"; }
                { fg = colors.base0E; mime = "application/rar"; }
                { fg = colors.base0E; mime = "application/xz"; }
                { fg = colors.base0B; mime = "application/doc"; }
                { fg = colors.base0B; mime = "application/pdf"; }
                { fg = colors.base0B; mime = "application/rtf"; }
                { fg = colors.base0B; mime = "application/vnd.*"; }
                { bold = true; fg = colors.base0D; url = "*/"; }
                { fg = colors.base05; mime = "*"; }
              ];
            };
            help = {
              desc = { fg = colors.base05; };
              footer = { fg = colors.base05; };
              hovered = { bg = colors.base03; fg = colors.base05; };
              on = { fg = colors.base0E; };
              run = { fg = colors.base0C; };
            };
            icon = {
              conds = [
                { fg = colors.base05; "if" = "orphan"; text = ""; }
                { fg = colors.base04; "if" = "link"; text = ""; }
                { fg = colors.base0A; "if" = "block"; text = ""; }
                { fg = colors.base0A; "if" = "char"; text = ""; }
                { fg = colors.base0A; "if" = "fifo"; text = ""; }
                { fg = colors.base0A; "if" = "sock"; text = ""; }
                { fg = colors.base0A; "if" = "sticky"; text = ""; }
                { fg = colors.base08; "if" = "dummy"; text = ""; }
                { fg = colors.base0D; "if" = "dir"; text = ""; }
                { fg = colors.base0B; "if" = "exec"; text = ""; }
                { fg = colors.base05; "if" = "!dir"; text = ""; }
              ];
              dirs = [
                { fg = colors.base09; name = ".config"; text = ""; }
                { fg = colors.base0C; name = ".git"; text = ""; }
                { fg = colors.base0D; name = ".github"; text = ""; }
                { fg = colors.base0D; name = ".npm"; text = ""; }
                { fg = colors.base0C; name = "Desktop"; text = ""; }
                { fg = colors.base0C; name = "Development"; text = ""; }
                { fg = colors.base0C; name = "Documents"; text = ""; }
                { fg = colors.base0C; name = "Downloads"; text = ""; }
                { fg = colors.base0C; name = "Library"; text = ""; }
                { fg = colors.base0C; name = "Movies"; text = ""; }
                { fg = colors.base0C; name = "Music"; text = ""; }
                { fg = colors.base0C; name = "Pictures"; text = ""; }
                { fg = colors.base0C; name = "Public"; text = ""; }
                { fg = colors.base0C; name = "Videos"; text = ""; }
              ];
            };
            indicator = { current = { bg = colors.base02; bold = true; }; preview = { bg = colors.base02; bold = true; }; };
            input = {
              border = { fg = colors.base0D; };
              selected = { bg = colors.base03; };
              title = { fg = colors.base05; };
              value = { fg = colors.base05; };
            };
            mgr = {
              syntect_theme = toString syntaxTheme;
              border_style = { fg = colors.base04; };
              count_copied = { bg = colors.base0B; fg = colors.base00; };
              count_cut = { bg = colors.base08; fg = colors.base00; };
              count_selected = { bg = colors.base0A; fg = colors.base00; };
              cwd = { fg = colors.base0C; };
              find_keyword = { bold = true; fg = colors.base0B; };
              find_position = { fg = colors.base0E; };
              marker_copied = { bg = colors.base0B; fg = colors.base0B; };
              marker_cut = { bg = colors.base08; fg = colors.base08; };
              marker_selected = { bg = colors.base0A; fg = colors.base0A; };
            };
            mode = {
              normal_alt = { bg = colors.base00; fg = colors.base0D; };
              normal_main = { bg = colors.base0D; bold = true; fg = colors.base00; };
              select_alt = { bg = colors.base00; fg = colors.base0B; };
              select_main = { bg = colors.base0B; bold = true; fg = colors.base00; };
              unset_alt = { bg = colors.base00; fg = colors.base0F; };
              unset_main = { bg = colors.base0F; bold = true; fg = colors.base00; };
            };
            pick = {
              active = { fg = colors.base0E; };
              border = { fg = colors.base0D; };
              inactive = { fg = colors.base05; };
            };
            status = {
              perm_exec = { fg = colors.base0B; };
              perm_read = { fg = colors.base0A; };
              perm_sep = { fg = colors.base0C; };
              perm_type = { fg = colors.base0D; };
              perm_write = { fg = colors.base08; };
              progress_error = { bg = colors.base00; fg = colors.base08; };
              progress_label = { bg = colors.base00; fg = colors.base05; };
              progress_normal = { bg = colors.base00; fg = colors.base05; };
            };
            tabs = {
              active = { bg = colors.base0D; bold = true; fg = colors.base00; };
              inactive = { bg = colors.base01; fg = colors.base0D; };
            };
            tasks = {
              border = { fg = colors.base0D; };
              hovered = { bg = colors.base03; fg = colors.base05; };
              title = { fg = colors.base05; };
            };
            which = {
              cand = { fg = colors.base0C; };
              desc = { fg = colors.base05; };
              mask = { bg = colors.base02; };
              rest = { fg = colors.base0F; };
              separator_style = { fg = colors.base04; };
            };
          };
        "yazi/yazi.toml".source = (pkgs.formats.toml { }).generate "yazi.toml" {
          mgr = {
            ratio = [
              1
              1
              1
            ];
            show_hidden = true;
          };
          opener = {
            edit = [
              {
                run = ''sudo hx "$@"'';
                desc = "Helix";
                block = true;
                for = "macos";
              }
              {
                run = ''hx "$@"'';
                desc = "Helix";
                block = true;
                for = "linux";
              }
            ];
          };
        };
      };
    };
}
