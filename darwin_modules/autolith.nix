{
  inputs,
  pkgs,
  ...
}: {
  environment.systemPackages = [
    inputs.autolith.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
