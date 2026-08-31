{ lib, pkgs, ... }:
{
  programs.kdeconnect = {
    enable = true;
    package = pkgs.valent;
  };

  services.gvfs.enable = true;

  systemd.user.services.valent = {
    description = "Valent device integration service";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];

    serviceConfig = {
      ExecStart = "${lib.getExe pkgs.valent} --gapplication-service";
      Environment = "SSH_AUTH_SOCK=%t/gcr/ssh";
      Restart = "on-failure";
    };
  };
}
