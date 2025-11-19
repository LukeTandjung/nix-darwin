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
    sensor.iio.enable = true;
    graphics.enable = true;
    microsoft-surface.kernelVersion = "longterm";
  };

  services = {
    iptsd.enable = true;
    thermald.enable = true;
  };

  config = {
    microsoft-surface.surface-control.enable = true;
  };
}
