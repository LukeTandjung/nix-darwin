
{ config, lib, pkgs, ... }:

{
  # System settings
  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_US.UTF-8";

  nixpkgs = {
    config.allowUnfree = true;
  };

  system.copySystemConfiguration = false;
  system.stateVersion = "unstable";
}
