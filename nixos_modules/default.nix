{ ... }:

{
  imports = [
    ./hardware.nix
    ./desktop.nix
    ./audio.nix
    ./network.nix
    ./power.nix
    ./users.nix
    ./packages.nix
    ./typst.nix
    ./stylix.nix
  ];
}
