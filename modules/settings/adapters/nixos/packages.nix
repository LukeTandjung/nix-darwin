{ ... }:
{
  modules.nixos.packages =
    { pkgs, ... }:

    {
      # Core system packages. pciutils gives us lspci/setpci for eGPU PCIe link
      # diagnosis and the Gen3 bridge cap service; usbutils is useful for USB4/TB
      # enclosure debugging.
      environment.systemPackages = with pkgs; [
        wget
        upower
        pciutils
        usbutils
        # secret-tool reads entries shared via KeePassXC's Secret Service
        # integration (single process, no master-key prompt).
        libsecret
        # Phase 0 local-LLM prerequisite: verify that RADV exposes the 780M.
        vulkan-tools
      ];

      # Fonts
      fonts.packages = with pkgs; [
        font-awesome
        jetbrains-mono
        ibm-plex
      ];
    };
}
