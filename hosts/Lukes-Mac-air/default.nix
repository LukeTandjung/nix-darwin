{ inputs, ... }:
let
  inherit (inputs)
    nixpkgs
    nixos-hardware
    rnote-nixpkgs
    flatpaks
    home-manager
    stylix
    zen-browser
    spicetify-nix
    dankMaterialShell
    leetgpu
    ;
  sharedHomeModules = [
    zen-browser.homeModules.beta
    spicetify-nix.homeManagerModules.spicetify
    leetgpu.homeManagerModules.default
    dankMaterialShell.homeModules.dank-material-shell
  ];
in
nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = { inherit rnote-nixpkgs; };
  modules = [
    ./configuration.nix
    ./hardware-configuration.nix
    ../../nixos_modules
    stylix.nixosModules.stylix
    nixos-hardware.nixosModules.framework-12-13th-gen-intel
    flatpaks.nixosModules.default
    home-manager.nixosModules.home-manager
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "hm-bak";
        users.luke = ../../home.nix;
        sharedModules = sharedHomeModules;
      };
    }
  ];
}
