{
  description = "Luke's Nix Darwin System";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    stylix.url = "github:nix-community/stylix";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      stylix,
      nix-darwin,
      home-manager,
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

          environment.systemPackages = with pkgs; [
            git
            aerospace
            raycast
            bartender
            postgresql
            dbeaver-bin
            postman
            docker
          ];

          users.users.luketandjung = {
            name = "luketandjung";
            home = "/Users/luketandjung";
          };

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
          ];
        };
    in
    {
      darwinConfigurations."Lukes-Mac-mini" = nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = { inherit pkgs inputs; };
        modules = [
          configuration
          stylix.darwinModules.stylix
          ./stylix.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.luketandjung = ./home.nix;
            home-manager.backupFileExtension = "hm-bak";
            # Optionally, use home-manager.extraSpecialArgs to pass
            # arguments to home.nix
          }
        ];
      };
    };
}
