{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    tailscale
    tailscale-gui
  ];
}
