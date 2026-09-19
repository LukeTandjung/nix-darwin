{ pkgs, ... }:
{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "with-github-token";
      runtimeInputs = [ pkgs.gh ];
      text = ''
        # Read the credential as the desktop user, before any sudo command.
        set +x
        if [[ $# -eq 0 ]]; then
          echo 'Usage: with-github-token COMMAND [ARG...]' >&2
          exit 2
        fi
        token=$(gh auth token --hostname github.com)
        if [[ -z "$token" ]]; then
          echo 'GitHub returned an empty token' >&2
          exit 1
        fi
        export NIX_CONFIG="''${NIX_CONFIG:+$NIX_CONFIG$'\n'}extra-access-tokens = github.com=$token"
        unset token
        exec "$@"
      '';
    })
  ];
}
