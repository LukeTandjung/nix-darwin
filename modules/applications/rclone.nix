{ ... }:
{
  modules.hjem.rclone = { config, lib, pkgs, ... }:
    let
      rclone-drive = pkgs.writeShellApplication {
        name = "rclone-drive";
        runtimeInputs = [ pkgs.coreutils pkgs.jq pkgs.libsecret ];
        text = ''
          set +x
          read_credential() {
            local title=$1
            secret-tool lookup Title "$title" || {
              echo "KeePassXC did not return $title" >&2
              return 1
            }
          }

          RCLONE_CONFIG_REMOTE_CLIENT_ID=$(read_credential RCLONE_CLIENT_ID) || exit 1
          RCLONE_CONFIG_REMOTE_CLIENT_SECRET=$(read_credential RCLONE_CLIENT_SECRET) || exit 1
          RCLONE_CONFIG_REMOTE_TOKEN=$(read_credential RCLONE_TOKEN) || exit 1

          if [[ -z "$RCLONE_CONFIG_REMOTE_CLIENT_ID" || "$RCLONE_CONFIG_REMOTE_CLIENT_ID" == *$'\n'* || "$RCLONE_CONFIG_REMOTE_CLIENT_ID" == *$'\r'* ]]; then
            echo 'KeePassXC did not return a valid RCLONE_CLIENT_ID' >&2
            exit 1
          fi
          if [[ -z "$RCLONE_CONFIG_REMOTE_CLIENT_SECRET" || "$RCLONE_CONFIG_REMOTE_CLIENT_SECRET" == *$'\n'* || "$RCLONE_CONFIG_REMOTE_CLIENT_SECRET" == *$'\r'* ]]; then
            echo 'KeePassXC did not return a valid RCLONE_CLIENT_SECRET' >&2
            exit 1
          fi
          if [[ -z "$RCLONE_CONFIG_REMOTE_TOKEN" ]] || ! jq -e . >/dev/null 2>&1 <<< "$RCLONE_CONFIG_REMOTE_TOKEN"; then
            echo 'KeePassXC did not return a valid RCLONE_TOKEN' >&2
            exit 1
          fi

          export RCLONE_CONFIG_REMOTE_CLIENT_ID RCLONE_CONFIG_REMOTE_CLIENT_SECRET RCLONE_CONFIG_REMOTE_TOKEN

          # OAuth refreshes must never persist outside KeePassXC.
          config_dir=$(mktemp -d /dev/shm/rclone-drive.XXXXXX)
          trap 'rm -rf -- "$config_dir"' EXIT
          install -m 600 ${lib.escapeShellArg "${config.xdg.config.directory}/rclone/rclone.conf"} "$config_dir/rclone.conf"

          ${lib.getExe pkgs.rclone} --config "$config_dir/rclone.conf" "$@"
        '';
      };
    in
    {
      packages = [ pkgs.rclone rclone-drive ];
      xdg.config.files."rclone/rclone.conf".text = ''
        [remote]
        type = drive
        scope = drive
      '';
    };
}
