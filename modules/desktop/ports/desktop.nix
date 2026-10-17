{ lib, ... }:
let
  # One desktop implementation can configure several programs and both layers.
  # This checks its shape, not feature parity between Linux and macOS desktops.
  desktop = lib.types.submodule {
    options = {
      platform = lib.mkOption {
        type = lib.types.enum [
          "nixos"
          "darwin"
        ];
        description = "System module class supported by this desktop implementation.";
      };
      system = lib.mkOption {
        type = lib.types.deferredModule;
        description = "System configuration required by the desktop.";
      };
      home = lib.mkOption {
        type = lib.types.deferredModule;
        description = "Hjem configuration required by the desktop.";
      };
    };
  };
in
{
  options.adapters.desktop = lib.mkOption {
    type = lib.types.attrsOf desktop;
    default = { };
    description = "Available desktop implementations. Registration does not enable them.";
  };

  options.hosts = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.desktop = lib.mkOption {
          type = desktop;
          description = "The complete desktop implementation selected by this host.";
        };
      }
    );
    default = { };
    description = "Per-host domain selections.";
  };
}
