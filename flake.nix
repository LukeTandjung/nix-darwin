{
  description = "Luke's Nix Darwin System";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    stylix.url = "github:nix-community/stylix/master";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      stylix,
      nix-darwin,
      home-manager,
      zen-browser,
      spicetify-nix,
    }:
    let
      system = "aarch64-darwin";
      # Create a pkgs set that allows unfree
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      configuration =
        {
          pkgs,
          inputs,
          ...
        }:
        {
          # List packages installed in system profile. To search by name, run:
          # $ nix-env -qaP | grep wgeti

          environment = {
            systemPackages = with pkgs; [
              git
              raycast
              dbeaver-bin
              postman
              notion-app
              typst
              typstyle
              typst-live
              tinymist
            ];
          };

          system.primaryUser = "luketandjung";

          users.users.luketandjung = {
            name = "luketandjung";
            home = "/Users/luketandjung";
          };

          security.sudo.extraConfig = ''
            %staff ALL = (ALL) NOPASSWD: ALL
          '';

          system.defaults.finder.QuitMenuItem = true;

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 6;

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";

          fonts.packages = with pkgs; [
            font-awesome
            jetbrains-mono
            ibm-plex
          ];

          system.activationScripts.postActivation.text = ''
            echo "Updated /private/etc/sudoers.d/yabai successfully!"
            su - "$(logname)" -c '${pkgs.skhd}/bin/skhd -r'
          '';
        };
    in
    {
      darwinConfigurations."Lukes-Mac-mini" = nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = { inherit pkgs inputs system; };
        modules = [
          configuration
          stylix.darwinModules.stylix
          ./darwin_modules
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.luketandjung = ./home.nix;
            home-manager.backupFileExtension = "hm-bak";
            home-manager.sharedModules = [
              inputs.zen-browser.homeModules.beta
              inputs.spicetify-nix.homeManagerModules.spicetify
            ];
            # Optionally, use home-manager.extraSpecialArgs to pass
            # arguments to home.nix
          }
        ];
      };
    };
}
