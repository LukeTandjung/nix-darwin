{ ... }:

{
  networking.hostName = "Lukes-Um790";

  # System settings
  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_US.UTF-8";

  nixpkgs.config = {
    allowUnfree = true;
  };

  # Test eGPU/USB4 stability by disabling PCIe ASPM.
  boot.kernelParams = [
    "pcie_ports=native"
    "pcie_aspm=off"
    "pcie_port_pm=off"
    "pcie=assign-busses,realloc"
    "thunderbolt.clx=0"
  ];

  system.copySystemConfiguration = false;
  system.stateVersion = "25.11";
}
