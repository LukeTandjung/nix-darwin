{ inputs, lib, pkgs, ... }:

{
  programs.zed-delta.skills.enable = true;
  programs.zed-delta.context.enable = true;

  home.packages = lib.optionals (builtins.elem pkgs.stdenv.hostPlatform.system [
    "x86_64-linux"
    "aarch64-linux"
  ]) [
    inputs.delta.packages.${pkgs.stdenv.hostPlatform.system}.delta-trunk
  ];
}
