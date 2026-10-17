{ inputs, ... }:
{
  modules.nixos.valent =
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
        after = [
          "graphical-session.target"
          "set-SSH_AUTH_SOCK.service"
        ];

        serviceConfig = {
          ExecStart = "${lib.getExe pkgs.valent} --gapplication-service";
          # Inherit the agent socket exported by Home Manager, like other GUI apps.
          Restart = "on-failure";
        };
      };
    };
}
