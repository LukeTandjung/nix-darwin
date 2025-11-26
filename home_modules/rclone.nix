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
            unmask = "0022";
          };
        };
      };
    };
  };
}
