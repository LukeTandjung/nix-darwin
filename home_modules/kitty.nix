{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  programs.kitty = {
    enable = true;
    package = pkgs.kitty;
    settings = {
      macos_option_as_alt = "yes";
    };
  };
}
