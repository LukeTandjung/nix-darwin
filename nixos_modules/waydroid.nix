{ pkgs, ... }:

{
  virtualisation.waydroid = {
    enable = true;
    # If Waydroid networking breaks on newer kernels, uncomment this:
    # package = pkgs.waydroid-nftables;
  };

  environment.systemPackages = with pkgs; [
    android-tools
    waydroid-helper
    wl-clipboard
  ];
}
