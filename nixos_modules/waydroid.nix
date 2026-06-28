{ pkgs, ... }:

{
  virtualisation.waydroid = {
    enable = true;
    package = pkgs.waydroid-nftables;
  };

  environment.systemPackages = with pkgs; [
    android-tools
    waydroid-helper
    wl-clipboard
  ];
}
