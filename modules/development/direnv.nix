{ ... }:
{
  modules.hjem.direnv = { pkgs, lib, ... }: {
    packages = [ pkgs.direnv pkgs.nix-direnv ];
    xdg.config.files."direnv/lib/nix-direnv.sh".text = ''
      source ${pkgs.nix-direnv}/share/nix-direnv/direnvrc
    '';
    zshInit = ''eval "$(${lib.getExe pkgs.direnv} hook zsh)"'';
  };
}
