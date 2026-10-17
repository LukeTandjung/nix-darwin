{ inputs, ... }:
{
  modules.home.direnv =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      programs.direnv = {
        enable = true;
        enableZshIntegration = true;
        nix-direnv.enable = true;
      };
    };
}
