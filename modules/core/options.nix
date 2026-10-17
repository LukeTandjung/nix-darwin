{ lib, ... }:
{
  options.builders = lib.mkOption {
    type = lib.types.attrsOf (lib.types.functionTo lib.types.package);
    default = { };
    description = "Domain-owned package builders, applied to the consuming host package set.";
  };

  options.modules = lib.genAttrs [ "nixos" "darwin" "hjem" ] (
    scope:
    lib.mkOption {
      type = lib.types.attrsOf lib.types.deferredModule;
      default = { };
      description = "Composable ${scope} modules, defined by feature and selected by profiles.";
    }
  );
}
