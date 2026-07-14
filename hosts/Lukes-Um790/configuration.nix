{ ... }:

{
  networking.hostName = "Lukes-Um790";

  # System settings
  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_US.UTF-8";

  nixpkgs.config = {
    allowUnfree = true;

    # Build CUDA consumers specifically for the RTX 5090 (Blackwell, SM 12.0).
    # Keep the patched NVIDIA kernel/userspace package in nvidia.nix unchanged;
    # these settings only control Nix CUDA package builds.
    cudaSupport = true;
    cudaCapabilities = [ "12.0" ];
  };

  # Keep kernel logs across hard reboots while diagnosing eGPU crashes. The
  # failing Vulkan path rebooted the machine before user-space logs could flush,
  # so persistent journald is necessary for post-mortem `journalctl -b -1`.
  services.journald.extraConfig = ''
    Storage=persistent
    SyncIntervalSec=1s
  '';

  # eGPU/USB4 stability: disable PCIe power management. ASPM/port PM can push
  # Thunderbolt PCIe devices through low-power transitions that are unsafe for
  # this Blackwell eGPU setup. NVIDIA DRM/KMS params are intentionally absent;
  # the AMD iGPU owns display and nvidia.nix keeps NVIDIA compute/offload-only.
  boot.kernelParams = [
    "pcie_aspm=off"
    "pcie_port_pm=off"
  ];

  system.copySystemConfiguration = false;
  system.stateVersion = "25.11";
}
