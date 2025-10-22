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
    kernelModules = [ "brcmfmac" ];
  };

  hardware = {
    enableAllFirmware = true;
    bluetooth.enable = true;
    sensor.iio.enable = true;
  };

  services.blueman.enable = true;
  services.libinput.enable = true;
}
