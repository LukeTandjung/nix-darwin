{ config, ... }:

{
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };
  };

  hardware = {
    enableAllFirmware = true;
    bluetooth.enable = true;
  };
}
