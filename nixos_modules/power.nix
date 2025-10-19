{ ... }:

{
  services.power-profiles-daemon.enable = true;
  powerManagement.cpuFreqGovernor = "ondemand";
}
