{ ... }:

{
  imports = [
    ./hardware.nix
    ./desktop.nix
    ./audio.nix
    ./networking.nix
    ./power.nix
    ./users.nix
    ./packages.nix
  ];
}
