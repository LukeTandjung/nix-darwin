lib: lib.darwinSystem' ({ config, pkgs, lib, inputs, ... }: {
  imports = [
    ./configuration.nix
    ../../darwin_modules
    inputs.stylix.darwinModules.stylix
    inputs.home-manager.darwinModules.home-manager
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-bak";
    users.luketandjung = ../../home.nix;
    sharedModules = [
      inputs.zen-browser.homeModules.beta
      inputs.spicetify-nix.homeManagerModules.spicetify
    ];
  };
})
