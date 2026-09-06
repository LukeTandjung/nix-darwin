{ lib, pkgs, ... }:

{
  programs.zed-delta = lib.mkIf (builtins.elem pkgs.stdenv.hostPlatform.system [
    "x86_64-linux"
    "aarch64-linux"
    "aarch64-darwin"
  ]) {
    enable = true;
  };
}
