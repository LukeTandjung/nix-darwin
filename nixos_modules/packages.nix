{ pkgs, inputs, ... }:

{
  # Core system packages. pciutils gives us lspci/setpci for eGPU PCIe link
  # diagnosis and the Gen3 bridge cap service; usbutils is useful for USB4/TB
  # enclosure debugging.
  environment.systemPackages = with pkgs; [
    wget
    upower
    pciutils
    usbutils
    # Phase 0 local-LLM prerequisite: verify that RADV exposes the 780M.
    vulkan-tools
  ];

  # Fonts
  fonts.packages = [
    inputs.luke-pkgs.packages.${pkgs.stdenv.hostPlatform.system}.terminal_grotesque
  ]
  ++ (with pkgs; [
    font-awesome
    jetbrains-mono
    ibm-plex
  ]);
}
