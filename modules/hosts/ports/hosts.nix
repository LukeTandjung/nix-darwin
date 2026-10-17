{ lib, ... }:
let
  adapter = lib.types.submodule {
    options = {
      platform = lib.mkOption {
        type = lib.types.enum [
          "nixos"
          "darwin"
        ];
        description = "System module class constructed by this adapter.";
      };
      build = lib.mkOption {
        type = lib.types.functionTo lib.types.raw;
        description = "Construct a host from { name, system, modules }, composing its selected settings and desktop.";
      };
    };
  };
in
{
  options.adapters.hosts = lib.mkOption {
    type = lib.types.attrsOf adapter;
    default = { };
    description = "Platform-specific host constructors.";
  };
  options.hosts = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.adapter = lib.mkOption {
          type = adapter;
          description = "Platform constructor selected by this machine.";
        };
      }
    );
  };
}
