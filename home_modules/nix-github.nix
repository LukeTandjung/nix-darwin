{ config, ... }:
{
  # Provision this private file from gh outside Nix evaluation.
  # Only the include path enters the Nix store, never the token.
  nix.extraOptions = ''
    !include ${config.xdg.configHome}/nix/github-token.conf
  '';
}
