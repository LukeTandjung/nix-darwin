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

  # Keep kernel logs across reboots for GPU diagnostics (`journalctl -b -1`).
  services.journald.settings.Journal = {
    Storage = "persistent";
    SyncIntervalSec = "1s";
  };

  system.copySystemConfiguration = false;
  system.stateVersion = "25.11";
}
