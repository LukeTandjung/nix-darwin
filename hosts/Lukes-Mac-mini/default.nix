{ inputs, ... }: let
  inherit (inputs) nix-darwin nixpkgs home-manager stylix zen-browser spicetify-nix dank-material-shell;
  sharedHomeModules = [
    zen-browser.homeModules.beta
    spicetify-nix.homeManagerModules.spicetify
  ];
in nix-darwin.lib.darwinSystem {
  system = "aarch64-darwin";
  modules = [
    ./configuration.nix
    ../../darwin_modules
    stylix.darwinModules.stylix
    home-manager.darwinModules.home-manager
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-bak";
    users.luketandjung = import ../../home.nix;
    sharedModules = sharedHomeModules;
  };
}
