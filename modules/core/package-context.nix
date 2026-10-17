{ inputs, ... }:
{
  # Public package outputs use the same root nixpkgs pin as host configurations.
  # Home modules apply their domain's builder to host pkgs, retaining overrides.
  perSystem = { system, ... }: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  };
}
