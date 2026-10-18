flake@{ inputs, ... }:
{
  hosts.Lukes-Mac-air = {
    adapter = flake.config.adapters.hosts.nixos;
    settings = flake.config.adapters.settings.nixos;
    desktop = flake.config.adapters.desktop.linux;
  };

  modules.nixos.Lukes-Mac-air = { ... }: {
    networking.hostName = "Lukes-Mac-air";

    # System settings
    time.timeZone = "Europe/London";
    i18n.defaultLocale = "en_US.UTF-8";

    nixpkgs.config = {
      allowUnfree = true;
    };

    system.copySystemConfiguration = false;
    system.stateVersion = "25.11";
  };

  flake.nixosConfigurations.Lukes-Mac-air = flake.config.hosts.Lukes-Mac-air.adapter.build {
    name = "Lukes-Mac-air";
    system = "x86_64-linux";
    modules = [
      flake.config.modules.nixos.Lukes-Mac-air
      flake.config.modules.nixos.Lukes-Mac-air-hardware
      inputs.nixos-hardware.nixosModules.framework-12-13th-gen-intel
    ];
  };
}
