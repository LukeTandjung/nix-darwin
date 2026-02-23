{ inputs, sharedHomeModules, ... }:
let
  inherit (inputs)
    nix-darwin
    home-manager
    stylix
    nix-homebrew
    ;
in
nix-darwin.lib.darwinSystem {
  system = "aarch64-darwin";
  specialArgs = { inherit inputs sharedHomeModules; };
  modules = [
    ./configuration.nix
    ../../darwin_modules
    stylix.darwinModules.stylix
    home-manager.darwinModules.home-manager
    nix-homebrew.darwinModules.nix-homebrew
  ];
}
