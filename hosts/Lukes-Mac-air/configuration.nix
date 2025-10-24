
{ config, lib, pkgs, ... }:

{
  # System settings
  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_US.UTF-8";

  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "broadcom-sta-6.30.223.271-57-6.12.54"
    ];
  };

  system.copySystemConfiguration = false;
  system.stateVersion = "25.11";
}
