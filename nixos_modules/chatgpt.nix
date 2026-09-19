{ inputs, ... }:
{
  imports = [
    inputs.codex-desktop-linux.nixosModules.default
  ];

  programs.codexDesktopLinux.enable = true;
}
