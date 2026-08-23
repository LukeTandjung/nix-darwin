{ inputs, pkgs, sharedHomeModules, ... }:
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
    extraSpecialArgs = { inherit inputs; };
    users.luke = ../home.nix;
    sharedModules = sharedHomeModules;
  };
}
