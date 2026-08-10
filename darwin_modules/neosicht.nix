{
  inputs,
  pkgs,
  ...
}: {
  environment.systemPackages = [
    inputs.neosicht.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
