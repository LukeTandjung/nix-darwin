
lib: lib.nixosSystem' ({ config, pkgs, lib, inputs, ... }: {
  imports = [
    ./configuration.nix
    ./hardware-configuration.nix
    inputs.stylix.nixosModules.stylix
    ../../nixos_modules
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-bak";
    users.luke = ../../home.nix;
    sharedModules = [
      inputs.zen-browser.homeModules.beta
      inputs.spicetify-nix.homeManagerModules.spicetify
    ];
  };

  system.stateVersion = "25.11";
})
