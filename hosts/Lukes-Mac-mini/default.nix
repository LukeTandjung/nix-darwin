{ inputs, ... }: let
  inherit (inputs) nix-darwin nixpkgs home-manager stylix zen-browser spicetify-nix dankMaterialShell leetgpu;
  sharedHomeModules = [
    zen-browser.homeModules.beta
    spicetify-nix.homeManagerModules.spicetify
    leetgpu.homeManagerModules.default
    dankMaterialShell.homeModules.dankMaterialShell.default
  ];
in nix-darwin.lib.darwinSystem {
  system = "aarch64-darwin";
  modules = [
    ./configuration.nix
    ../../darwin_modules
    stylix.darwinModules.stylix
    home-manager.darwinModules.home-manager {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "hm-bak";
        users.luketandjung = ../../home.nix;
        sharedModules = sharedHomeModules;
      };
    }
  ];
}
