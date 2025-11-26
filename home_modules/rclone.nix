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
        client_id = "~/secrets/rclone_client_id";
        client_secret = "$~/secrets/rclone_client_secret";
        token = "$~/secrets/rclone_token.json";
      };

      mounts = {
        "Documents" = {
          enable = true;
          mountPoint = "$~/Documents";
          options = {
            vfs-cache-mode = "writes";
            dir-cache-time = "12h";
            poll-interval = "30s";
            cache-dir = "~/.cache/rclone";
            unmask = "0022";
          };
        }
      };
    };
  };
}
