{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  programs.rclone = {
    enable = true;

    remotes.remote = {
      config = {
        type = "drive";
        scope = "drive";
      };

      secrets = {
        client_id = "${config.home.homeDirectory}/secrets/rclone_client_id";
        client_secret = "${config.home.homeDirectory}/secrets/rclone_client_secret";
        token = "${config.home.homeDirectory}/secrets/rclone_token.json";
      };

      mounts = {
        "Documents" = {
          enable = true;
          mountPoint = "${config.home.homeDirectory}/Documents";
          options = {
            vfs-cache-mode = "writes";
            dir-cache-time = "12h";
            poll-interval = "30s";
            cache-dir = "${config.home.homeDirectory}/.cache/rclone";
            umask = "0022";
          };
        };
        "Pictures" = {
          enable = true;
          mountPoint = "${config.home.homeDirectory}/Pictures";
          options = {
            vfs-cache-mode = "full";
            vfs-cache-max-size = "1G";
            vfs-cache-max-age = "168h";
            vfs-read-chunk-size = "16M";
            vfs-read-chunk-size-limit = "64M";
            vfs-read-ahead = "64M";
            dir-cache-time = "24h";
            attr-timeout = "24h";
            poll-interval = "1m";
            cache-dir = "${config.home.homeDirectory}/.cache/rclone";
            umask = "0022";
          };
        };
      };
    };
  };
}
