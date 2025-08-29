{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  programs.yazi = {
    enable = true;
    package = pkgs.yazi;
    enableZshIntegration = true;
    settings = {
      mgr = {
        ratio = [
          1
          1
          1
        ];
        show_hidden = true;
      };
    };
  };
}
