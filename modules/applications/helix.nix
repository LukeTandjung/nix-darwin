{ inputs, ... }:
{
  # Theme mapping adapted from Tinted Theming (https://github.com/tinted-theming).
  modules.hjem.helix =
    { pkgs, theme, lib, ... }:
    let
      colors = theme.colors;
    in {
      packages = [ pkgs.helix ];
      xdg.config.files = {
        "helix/themes/kanagawa.toml".source =
          (pkgs.formats.toml { }).generate "kanagawa.toml" {
            attribute = "base09";
            comment = { fg = "base03"; modifiers = [ "italic" ]; };
            constant = "base09";
            "constant.character.escape" = "base0C";
            "constant.numeric" = "base09";
            constructor = "base0D";
            debug = "base03";
            diagnostic = { modifiers = [ "underlined" ]; };
            "diff.delta" = "base09";
            "diff.minus" = "base08";
            "diff.plus" = "base0B";
            error = "base08";
            function = "base0D";
            hint = "base03";
            info = "base0D";
            keyword = "base0E";
            label = "base0E";
            namespace = "base0E";
            operator = "base05";
            special = "base0D";
            string = "base0B";
            tag = "base08";
            type = "base0A";
            variable = "base08";
            "variable.other.member" = "base0D";
            warning = "base09";
            "markup.bold" = { fg = "base0A"; modifiers = [ "bold" ]; };
            "markup.heading.1" = { fg = "base0D"; modifiers = [ "bold" ]; };
            "markup.heading.2" = { fg = "base08"; modifiers = [ "bold" ]; };
            "markup.heading.3" = { fg = "base09"; modifiers = [ "bold" ]; };
            "markup.heading.4" = { fg = "base0A"; modifiers = [ "bold" ]; };
            "markup.heading.5" = { fg = "base0B"; modifiers = [ "bold" ]; };
            "markup.heading.6" = { fg = "base0C"; modifiers = [ "bold" ]; };
            "markup.italic" = { fg = "base0E"; modifiers = [ "italic" ]; };
            "markup.link.text" = "base08";
            "markup.link.url" = { fg = "base09"; modifiers = [ "underlined" ]; };
            "markup.list" = "base08";
            "markup.quote" = "base0C";
            "markup.raw" = "base0B";
            "markup.strikethrough" = { modifiers = [ "crossed_out" ]; };
            "diagnostic.hint" = { underline = { style = "curl"; }; };
            "diagnostic.info" = { underline = { style = "curl"; }; };
            "diagnostic.warning" = { underline = { style = "curl"; }; };
            "diagnostic.error" = { underline = { style = "curl"; }; };
            "ui.background" = { bg = "base00"; };
            "ui.bufferline.active" = { fg = "base00"; bg = "base03"; modifiers = [ "bold" ]; };
            "ui.bufferline" = { fg = "base04"; bg = "base00"; };
            "ui.cursor" = { fg = "base06"; modifiers = [ "reversed" ]; };
            "ui.cursor.primary" = { fg = "base05"; modifiers = [ "reversed" ]; };
            "ui.cursorline.primary" = { fg = "base05"; bg = "base01"; };
            "ui.cursor.match" = { fg = "base05"; bg = "base02"; modifiers = [ "bold" ]; };
            "ui.cursor.select" = { fg = "base05"; modifiers = [ "reversed" ]; };
            "ui.gutter" = { bg = "base00"; };
            "ui.help" = { fg = "base06"; bg = "base01"; };
            "ui.linenr" = { fg = "base03"; bg = "base00"; };
            "ui.linenr.selected" = { fg = "base04"; bg = "base01"; modifiers = [ "bold" ]; };
            "ui.menu" = { fg = "base05"; bg = "base01"; };
            "ui.menu.scroll" = { fg = "base03"; bg = "base01"; };
            "ui.menu.selected" = { fg = "base01"; bg = "base04"; };
            "ui.popup" = { bg = "base01"; };
            "ui.selection" = { bg = "base02"; };
            "ui.selection.primary" = { bg = "base02"; };
            "ui.statusline" = { fg = "base04"; bg = "base01"; };
            "ui.statusline.inactive" = { bg = "base01"; fg = "base03"; };
            "ui.statusline.insert" = { fg = "base00"; bg = "base0B"; };
            "ui.statusline.normal" = { fg = "base00"; bg = "base03"; };
            "ui.statusline.select" = { fg = "base00"; bg = "base0F"; };
            "ui.text" = "base05";
            "ui.text.directory" = "base0D";
            "ui.text.focus" = "base05";
            "ui.virtual.indent-guide" = { fg = "base03"; };
            "ui.virtual.inlay-hint" = { fg = "base03"; };
            "ui.virtual.ruler" = { bg = "base01"; };
            "ui.virtual.jump-label" = { fg = "base0A"; modifiers = [ "bold" ]; };
            "ui.virtual.whitespace" = { fg = "base03"; };
            "ui.window" = { bg = "base01"; };
            palette = {
              base00 = colors.base00;
              base01 = colors.base01;
              base02 = colors.base02;
              base03 = colors.base03;
              base04 = colors.base04;
              base05 = colors.base05;
              base06 = colors.base06;
              base07 = colors.base07;
              base08 = colors.base08;
              base09 = colors.base09;
              base0A = colors.base0A;
              base0B = colors.base0B;
              base0C = colors.base0C;
              base0D = colors.base0D;
              base0E = colors.base0E;
              base0F = colors.base0F;
            };
          };
        "helix/languages.toml".source = (pkgs.formats.toml { }).generate "helix-languages.toml" {
          language-server = {
            nixd.command = "${pkgs.nixd}/bin/nixd";
            typescript-language-server = {
              command = "${pkgs.typescript-language-server}/bin/typescript-language-server";
              args = [ "--stdio" ];
            };
            tailwindcss-ls = {
              command = "${pkgs.tailwindcss-language-server}/bin/tailwindcss-language-server";
              args = [ "--stdio" ];
            };
            # This language server is responsible for handling regular HTML, CSS, JS, and JSON!
            vscode-langservers-extracted = {
              command = "${pkgs.vscode-langservers-extracted}/bin/vscode-langservers-extracted";
              args = [ "--stdio" ];
            };
            rust-analyzer.command = "${pkgs.rust-analyzer}/bin/rust-analyzer";
            ty = {
              command = "${pkgs.ty}/bin/ty";
              args = [ "server" ];
            };
          };
          language = [
            {
              name = "nix";
              language-servers = [ "nixd" ];
              auto-format = true;
              formatter.command = lib.getExe pkgs.nixfmt;
              file-types = [ "nix" ];
            }
            {
              name = "typst";
              language-servers = [ "tinymist" ];
              auto-format = true;
              formatter.command = "typstyle";
              file-types = [ "typ" ];
            }
            {
              name = "typescript";
              language-servers = [
                "typescript-language-server"
                "tailwindcss-ls"
                "vscode-langservers-extracted"
              ];
              auto-format = true;
              formatter = {
                command = "${pkgs.prettier}/bin/prettier";
                args = [ "--parser" "typescript" ];
              };
              file-types = [ "ts" ];
            }
            {
              name = "tsx";
              language-servers = [
                "typescript-language-server"
                "tailwindcss-ls"
                "vscode-langservers-extracted"
              ];
              auto-format = true;
              formatter = {
                command = "${pkgs.prettier}/bin/prettier";
                args = [ "--parser" "typescript" ];
              };
              file-types = [ "tsx" ];
            }
            {
              name = "rust";
              language-servers = [ "rust-analyzer" ];
              auto-format = false;
              file-types = [ "rs" ];
            }
            {
              name = "python";
              language-servers = [ "ty" ];
              auto-format = true;
              file-types = [ "py" ];
            }
          ];
        };
        "helix/config.toml".source = (pkgs.formats.toml { }).generate "helix-config.toml" {
          theme = "kanagawa";
        };
      };
    };
}
