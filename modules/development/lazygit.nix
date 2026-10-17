{ inputs, ... }:
{
  modules.home.lazygit =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      programs.lazygit = {
        enable = true;
        package = pkgs.lazygit;
      };
    };
}
