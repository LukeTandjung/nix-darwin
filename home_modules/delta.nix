{ inputs, lib, pkgs, ... }:

{
  home.packages = lib.optionals (builtins.elem pkgs.stdenv.hostPlatform.system [
    "x86_64-linux"
    "aarch64-linux"
  ]) [
    inputs.delta.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
