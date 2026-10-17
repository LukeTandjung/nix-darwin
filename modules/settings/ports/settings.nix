{ lib, ... }:
let
  settings = lib.types.submodule {
    options = {
      platform = lib.mkOption {
        type = lib.types.enum [
          "nixos"
          "darwin"
        ];
        description = "System module class supported by these settings.";
      };
      system = lib.mkOption {
        type = lib.types.deferredModule;
        description = "Platform system settings.";
      };
      home = lib.mkOption {
        type = lib.types.deferredModule;
        description = "User settings accompanying this platform.";
      };
    };
  };
in
{
  options.adapters.settings = lib.mkOption {
    type = lib.types.attrsOf settings;
    default = { };
    description = "Settings implementations; hosts select which one to use.";
  };
  options.hosts = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.settings = lib.mkOption {
          type = settings;
          description = "Settings implementation selected by this host.";
        };
      }
    );
  };
}
