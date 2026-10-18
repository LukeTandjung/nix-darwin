flake@{ ... }:
{
  hosts.Lukes-MacBook-Pro = {
    adapter = flake.config.adapters.hosts.darwin;
    settings = flake.config.adapters.settings.darwin;
    desktop = flake.config.adapters.desktop.macos;
  };

  modules.darwin.Lukes-MacBook-Pro = { pkgs, ... }: {
    system.primaryUser = "luketandjung";

    users.users.luketandjung = {
      name = "luketandjung";
      home = "/Users/luketandjung";
    };

    security.sudo.extraConfig = ''
      %staff ALL = (ALL) NOPASSWD: ALL
    '';

    system.defaults.finder = {
      QuitMenuItem = true;
      AppleShowAllFiles = true;
    };

    nixpkgs = {
      hostPlatform = "aarch64-darwin";
      config.allowUnfree = true;
    };

    fonts.packages = with pkgs; [
      font-awesome
      jetbrains-mono
      ibm-plex
    ];

    networking.hostName = "Lukes-MacBook-Pro";

    system.stateVersion = 6;
  };

  flake.darwinConfigurations.Lukes-MacBook-Pro = flake.config.hosts.Lukes-MacBook-Pro.adapter.build {
    name = "Lukes-MacBook-Pro";
    system = "aarch64-darwin";
    modules = [
      flake.config.modules.darwin.Lukes-MacBook-Pro
    ];
  };
}
