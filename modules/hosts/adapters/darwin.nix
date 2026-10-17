{
  config,
  inputs,
  lib,
  ...
}:
{
  adapters.hosts.darwin = {
    platform = "darwin";
    build =
      {
        name,
        system,
        modules,
      }:
      let
        host = config.hosts.${name};
      in
      assert lib.assertMsg (lib.hasSuffix "-darwin" system)
        "${name}: darwin host adapter cannot build ${system}.";
      assert lib.assertMsg (
        host.desktop.platform == "darwin"
      ) "${name}: desktop adapter must support darwin.";
      assert lib.assertMsg (
        host.settings.platform == "darwin"
      ) "${name}: settings adapter must support darwin.";
      inputs.nix-darwin.lib.darwinSystem {
        inherit system;
        modules = [
          config.modules.darwin.default
          inputs.hjem.darwinModules.default
          host.settings.system
          host.desktop.system
          {
            hjem.users.luketandjung.imports = [
              host.settings.home
              host.desktop.home
            ];
          }
        ]
        ++ modules;
      };
  };
}
