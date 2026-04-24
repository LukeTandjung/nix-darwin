{ config, lib, ... }:

lib.mkIf (config.networking.hostName == "Lukes-Um790") {
  services.xserver.videoDrivers = [
    "amdgpu"
    "nvidia"
  ];

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };

    nvidia = {
      modesetting.enable = true;
      # Blackwell (RTX 5090) requires the open kernel modules.
      open = true;
      nvidiaSettings = true;
      # Blackwell needs >= 570; beta tracks the newest upstream driver.
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      powerManagement.enable = false;
      powerManagement.finegrained = false;

      prime = {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };

        # PRIME Bus IDs use decimal PCI addresses, not the hex shown by lspci.
        amdgpuBusId = "PCI:196@0:0:0";
        nvidiaBusId = "PCI:102@0:0:0";
      };
    };
  };

  # Thunderbolt/USB4 device authorization for the Aorus eGPU enclosure.
  services.hardware.bolt.enable = true;

  # Render GL/Vulkan apps on the 5090 by default; compositor stays on amdgpu.
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
  };
}
