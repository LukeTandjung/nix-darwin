{ ... }:
{
  modules.hjem.oh-my-posh = { config, pkgs, lib, ... }: {
    packages = [ pkgs.oh-my-posh ];
    xdg.config.files."oh-my-posh/config.json".source = ./kanagawa.omp.json;
    zshInit = ''
      eval "$(${lib.getExe pkgs.oh-my-posh} init zsh --config ${lib.escapeShellArg "${config.xdg.config.directory}/oh-my-posh/config.json"})"
    '';
  };
}
