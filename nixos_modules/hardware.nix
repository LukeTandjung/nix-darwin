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
    # These options are Framework 12 specific modules!
    initrd.kernelModules = [ "pinctrl_tigerlake" ];
    kernelModules = [ "soc_button_array" ];
  };

  hardware = {
    enableAllFirmware = true;
    bluetooth.enable = true;
  };
}
