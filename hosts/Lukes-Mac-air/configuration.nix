
{ config, lib, pkgs, ... }:

{
  networking.hostName = "Lukes-Mac-air";

  # System settings
  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_US.UTF-8";

  nixpkgs.config = {
    allowUnfree = true;
  };

  system.copySystemConfiguration = false;
  system.stateVersion = "25.11";
}
