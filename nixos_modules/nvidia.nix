{ config, pkgs, ... }:

let
  # Retain the pinned Blackwell stability patches used with the former AORUS
  # eGPU setup. The RTX 5090 is now connected directly to the motherboard.
  # https://github.com/NVIDIA/open-gpu-kernel-modules/issues/979
  nvidiaDriverInjector = pkgs.fetchFromGitHub {
    owner = "apnex";
    repo = "nvidia-driver-injector";
    rev = "556f8e4f4059d806337f44c9e40714821ac837a4";
    hash = "sha256-MGz+FWU8UC8MPq/Eoyqp8DE62eV0PM3r7aJ1B5kbinE=";
  };

  injectorPatch = path: "${nvidiaDriverInjector}/patches/${path}";

  # Keep this exact driver version: the patchset targets its source tree.
  patchedNvidiaPackage = config.boot.kernelPackages.nvidiaPackages.mkDriver {
    version = "595.71.05";
    sha256_64bit = "sha256-NiA7iWC35JyKQva6H1hjzeNKBek9KyS3mK8G3YRva4I=";
    openSha256 = "sha256-Lfz71QWKM6x/jD2B22SWpUi7/og30HRlXg1kL3EWzEw=";
    settingsSha256 = "sha256-mXnf3jyvznfB3OfKd657rxv0rYHQb/dX/Riw/+N9EKU=";
    persistencedSha256 = "sha256-Z/6IvEEa/XfZ5F5qoSIPvXJLGtscYVqjFxHZaN/M2Ts=";

    patchesOpen = (map injectorPatch [
      "base/C1-kbuild-version-mk.patch"
      "base/C2-aer-internal-unmask.patch"
      "base/C3-gpu-lost-retry.patch"
      "base/C4-err-handlers-scaffold.patch"
      "base/E1-egpu-detection.patch"
      "base/C5-crash-safety.patch"
      "addon/A1-pcie-primitives.patch"
      "addon/A2-bus-loss-watchdog.patch"
      "addon/A3-recovery.patch"
      "addon/A4-close-path-telemetry.patch"
      "addon/A5-version-and-toggles.patch"
    ]) ++ [
      # A5 changes the kernel wrapper version, but NVIDIA's modeset core and
      # userspace still use 595.71.05. nvkms_get_kapi_funcs rejects DRM's table
      # when these strings differ. Keep every functional patch; undo only the
      # version suffix so KAPI, userspace and firmware agree on the ABI version.
      (pkgs.writeText "nvidia-aorus-display-version.patch" ''
        --- a/version.mk
        +++ b/version.mk
        @@ -1,2 +1,2 @@
        -NVIDIA_VERSION = 595.71.05-aorus.17
        +NVIDIA_VERSION = 595.71.05
         NVIDIA_NVID_VERSION = 595.71.05
      '')
    ];
  };
in
{
  services.xserver.videoDrivers = [ "amdgpu" "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    # Blackwell requires the open kernel modules.
    open = true;
    package = patchedNvidiaPackage;
    nvidiaSettings = true;
    nvidiaPersistenced = true;
    # Retain the tested power-management policy while simplifying boot setup.
    powerManagement.enable = false;
    powerManagement.finegrained = false;
  };

  # Load display drivers before userspace starts. No Thunderbolt authorization,
  # PCI rescan, bridge speed cap, or delayed module loading is needed internally.
  boot.initrd.kernelModules = [ "amdgpu" "nvidia" "nvidia_modeset" "nvidia_drm" ];
  boot.kernelModules = [ "nvidia_uvm" ];
  boot.extraModprobeConfig = ''
    options nvidia NVreg_DynamicPowerManagement=0x00
    options nvidia NVreg_PreserveVideoMemoryAllocations=0
    options nvidia NVreg_EnableS0ixPowerManagement=0
  '';
}
