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
    
    # Broadcom WiFi drivers for older MacBooks
    extraModulePackages = with config.boot.kernelPackages; [ broadcom_sta ];
    kernelModules = [ "wl" ];
    blacklistedKernelModules = [ "b43" "bcma" "brcmfmac" "brcmsmac" ];
  };

  hardware = {
    enableAllFirmware = true;
    bluetooth.enable = true;
    sensor.iio.enable = true;
  };

  services.blueman.enable = true;
  services.libinput.enable = true;
}
