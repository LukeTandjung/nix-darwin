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
    languages.language = [
      {
        name = "nix";
        auto-format = true;
        formatter.command = lib.getExe pkgs.nixfmt-rfc-style;
      }
      {
        name = "typst";
        auto-format = true;
        formatter.command = "typstyle";
      }
    ];
    settings = {
      keys.normal = {
        C.y = [
          ":sh rm -f /tmp/unique-file"
          ":insert-output yazi %{buffer_name} --chooser-file=/tmp/unique-file"
          ":insert-output echo '\x1b[?1049h\x1b[?2004h' > /dev/tty"
          ":open %sh{sudo cat /tmp/unique-file}"
          ":redraw"
        ];
        C.g = [
          ":new"
          ":insert-output lazygit"
          ":buffer-close!"
          ":redraw"
        ];
      };
    };
  };
}
