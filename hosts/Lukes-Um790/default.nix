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
  specialArgs = { inherit inputs rnote-nixpkgs sharedHomeModules; };
  modules = [
    ./configuration.nix
    ./hardware-configuration.nix
    ../../nixos_modules
    stylix.nixosModules.stylix
    flatpaks.nixosModules.default
    home-manager.nixosModules.home-manager
  ];
}
