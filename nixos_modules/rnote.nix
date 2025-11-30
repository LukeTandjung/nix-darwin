{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    rnote
    libinput
  ];
}
