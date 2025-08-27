{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  programs.zellij = {
    enable = true;
    package = pkgs.zellij;
    enableZshIntegration = true;
    attachExistingSession = true;
    exitShellOnExit = false;
  };
}
