{ config, inputs, pkgs, ... }:

let
  waydroidScript = inputs.nur.legacyPackages.${pkgs.stdenv.hostPlatform.system}.repos.ataraxiasjel.waydroid-script;
in
{
  virtualisation.waydroid = {
    enable = true;
    package = pkgs.waydroid-nftables;
  };

  environment.systemPackages = with pkgs; [
    android-tools
    waydroid-helper
    waydroidScript
    wl-clipboard
  ];

  systemd.services.waydroid-libhoudini = {
    description = "Install libhoudini ARM translation into Waydroid";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    before = [ "waydroid-container.service" ];

    path = [
      config.virtualisation.waydroid.package
    ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      set -euo pipefail

      marker=/var/lib/waydroid/.nix-libhoudini-installed
      if [ -e "$marker" ]; then
        echo "libhoudini is already marked as installed"
        exit 0
      fi

      if [ ! -e /var/lib/waydroid/images/system.img ] && [ ! -e /var/lib/waydroid/system.img ]; then
        echo "Waydroid is not initialized yet; run 'sudo waydroid init -s GAPPS', then 'sudo systemctl start waydroid-libhoudini.service'"
        exit 0
      fi

      ${waydroidScript}/bin/waydroid-script install libhoudini
      touch "$marker"
    '';
  };
}
