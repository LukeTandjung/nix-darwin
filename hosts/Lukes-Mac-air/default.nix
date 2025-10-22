{ inputs, ... }: let
  inherit (inputs) nixpkgs home-manager stylix zen-browser spicetify-nix dankMaterialShell;
  sharedHomeModules = [
    # While importing Stylix as a NixOS module also does so for HM, rebuilding without explicitly
    # importing the HM module causes build errors. Apparently this is because it is not imported
    # into HM user subtree at runtime.
    stylix.homeModules.stylix
    zen-browser.homeModules.beta
    spicetify-nix.homeManagerModules.spicetify
    dankMaterialShell.homeModules.dankMaterialShell.default
  ];
in nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    ./configuration.nix
    ./hardware-configuration.nix
    ../../nixos_modules
    stylix.nixosModules.stylix
    home-manager.nixosModules.home-manager {
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
