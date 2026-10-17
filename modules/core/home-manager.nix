flake@{ inputs, ... }:
let
  sharedHomeModules = [
    inputs.zen-browser.homeModules.beta
    inputs.spicetify-nix.homeManagerModules.spicetify
  ];
  homeManager =
    username:
    { pkgs, ... }:
    {
      home-manager = {
        # Preserve any unmanaged file that would otherwise block activation. The
        # suffix is made unique so repeated rebuilds do not fail on an existing
        # backup.
        backupCommand = "${pkgs.writeShellScript "home-manager-backup" ''
          set -euo pipefail

          for target in "$@"; do
            backup="$target.hm-backup"
            if [ -e "$backup" ] || [ -L "$backup" ]; then
              i=1
              while [ -e "$target.hm-backup-$i" ] || [ -L "$target.hm-backup-$i" ]; do
                i=$((i + 1))
              done
              backup="$target.hm-backup-$i"
            fi

            mv "$target" "$backup"
          done
        ''}";

        useGlobalPkgs = true;
        useUserPackages = true;
        users.${username} = flake.config.modules.home.default;
        sharedModules = sharedHomeModules;
      };
    };
in
{
  modules.nixos.home-manager = homeManager "luke";
  modules.darwin.home-manager = homeManager "luketandjung";
}
