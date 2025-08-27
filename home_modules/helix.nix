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
  };
}
