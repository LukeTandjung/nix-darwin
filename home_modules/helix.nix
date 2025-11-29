{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  programs.helix = {
    package = pkgs.helix;
    enable = true;
    languages = {
      language-server = {
        nixd.command = "${pkgs.nixd}/bin/nixd";
        typescript-language-server = {
          command = "${pkgs.nodePackages.typescript-language-server}/bin/typescript-language-server";
          args = [ "--stdio" ];
        };
        tailwindcss-ls = {
          command = "${pkgs.tailwindcss-language-server}/bin/tailwindcss-language-server";
          args = [ "--stdio" ];
        };
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
          formatter.command = lib.getExe pkgs.nixfmt-rfc-style;
          file-types = [
            "nix"
          ];
        }
        {
          name = "typst";
          language-servers = [ "tinymist" ];
          auto-format = true;
          formatter.command = "typstyle";
          file-types = [
            "typ"
          ];
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
            args = [
              "--parser"
              "typescript"
            ];
          };
          file-types = [
            "ts"
          ];
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
            args = [
              "--parser"
              "typescript"
            ];
          };
          file-types = [
            "tsx"
          ];
        }
        {
          name = "rust";
          language-servers = [ "rust-analyzer" ];
          auto-format = false;
          file-types = [
            "rs"
          ];
        }
        {
          name = "python";
          language-servers = [ "ty" ];
          auto-format = true;
          file-types = [
            "py"
          ];
        }
      ];
    };
    settings = {
      keys.normal = {
        "C-y" = [
          ":sh rm -f /tmp/unique-file"
          ":insert-output yazi %{buffer_name} --chooser-file=/tmp/unique-file"
          ":insert-output echo '\x1b[?1049h\x1b[?2004h' > /dev/tty"
          ":open %sh{sudo cat /tmp/unique-file}"
          ":redraw"
        ];
        "C-g" = [
          ":new"
          ":insert-output lazygit"
          ":buffer-close!"
          ":redraw"
        ];
      };
    };
  };
}
