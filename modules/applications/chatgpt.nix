{ inputs, ... }:
{
  modules.nixos.chatgpt = { ... }: {
    imports = [ inputs.codex-desktop-linux.nixosModules.default ];

    programs.codexDesktopLinux.enable = true;
  };

  modules.darwin.chatgpt = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.chatgpt ];
  };
}
