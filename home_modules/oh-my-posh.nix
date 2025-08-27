{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  programs.oh-my-posh = {
    enable = true;
    package = pkgs.oh-my-posh;
    enableZshIntegration = true;
    settings = builtins.fromJSON (builtins.readFile ./assets/kanagawa.omp.json);
  };
}
