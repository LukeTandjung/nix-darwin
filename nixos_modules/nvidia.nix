{ config, lib, pkgs, ... }:

lib.mkIf (config.networking.hostName == "Lukes-Um790") {
  services.xserver.videoDrivers = [ "nvidia" ];

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
      package = config.boot.kernelPackages.nvidiaPackages.beta;
      powerManagement.enable = false;
    };
  };

  # Thunderbolt/USB4 device authorization for the Aorus eGPU enclosure.
  services.hardware.bolt.enable = true;

  # Render GL/Vulkan apps on the 5090 by default; compositor stays on amdgpu.
  environment.sessionVariables = {
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    __NV_PRIME_RENDER_OFFLOAD = "1";
    __VK_LAYER_NV_optimus     = "NVIDIA_only";
    LIBVA_DRIVER_NAME         = "nvidia";
  };
}
