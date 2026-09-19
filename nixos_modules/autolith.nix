{
  inputs,
  pkgs,
  ...
}: {
  environment.systemPackages = [
    inputs.luke-pkgs.packages.${pkgs.stdenv.hostPlatform.system}.autolith
  ];
}
