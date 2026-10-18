{ config, inputs, lib, ... }:
{
  adapters.hosts.nixos = {
    platform = "nixos";
    build = { name, system, modules }:
      let
        host = config.hosts.${name};
      in
      assert lib.assertMsg (lib.hasSuffix "-linux" system)
        "${name}: nixos host adapter cannot build ${system}.";
      assert lib.assertMsg (host.desktop.platform == "nixos")
        "${name}: desktop adapter must support nixos.";
      assert lib.assertMsg (host.settings.platform == "nixos")
        "${name}: settings adapter must support nixos.";
      inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          config.modules.nixos.default
          inputs.hjem.nixosModules.default
          host.settings.system
          host.desktop.system
          {
            hjem.users.luke.imports = [
              host.settings.home
              host.desktop.home
            ];
          }
        ]
        ++ modules;
      };
  };
}
