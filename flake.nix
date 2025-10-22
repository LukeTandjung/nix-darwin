{
  description = "Luke's Nix Darwin/NixOS System Flake";

  nixConfig = {
    experimental-features = [
      "flakes"
      "nix-command"
      "pipe-operators"
    ];
    trusted-users = [ "root" "luke" "luketandjung" ];
  };

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
    dank-material-shell = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs @ {
      self,
      nixpkgs,
      stylix,
      nix-darwin,
      home-manager,
      zen-browser,
      spicetify-nix,
      dank-material-shell,
      ...
    }:
    let
      sharedHomeModules = [
        zen-browser.homeModules.beta
        spicetify-nix.homeManagerModules.spicetify
      ];
    in {
      nixosConfigurations.Lukes-Mac-air =
        import ./hosts/Lukes-Mac-air {
          inherit inputs sharedHomeModules;
        };

      darwinConfigurations.Lukes-Mac-mini =
        import ./hosts/Lukes-Mac-mini {
          inherit inputs sharedHomeModules;
        };
    };
}
