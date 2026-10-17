{ inputs, ... }:
{
  modules.home.oh-my-posh =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      programs.oh-my-posh = {
        enable = true;
        package = pkgs.oh-my-posh;
        enableZshIntegration = true;
        settings = builtins.fromJSON (builtins.readFile ../../assets/kanagawa.omp.json);
      };
    };
}
