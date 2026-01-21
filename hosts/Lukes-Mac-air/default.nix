{ inputs, sharedHomeModules, ... }:
let
  inherit (inputs)
    nixpkgs
    nixos-hardware
    rnote-nixpkgs
    flatpaks
    home-manager
    stylix
    ;
in
nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = { inherit rnote-nixpkgs sharedHomeModules; };
  modules = [
    ./configuration.nix
    ./hardware-configuration.nix
    ../../nixos_modules
    stylix.nixosModules.stylix
    nixos-hardware.nixosModules.framework-12-13th-gen-intel
    flatpaks.nixosModules.default
    home-manager.nixosModules.home-manager
  ];
}
