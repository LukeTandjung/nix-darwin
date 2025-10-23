{
  description = "Luke's Nix Darwin/NixOS System Flake";

  nixConfig = {
    experimental-features = "nix-command flakes pipe-operators";
    trusted-users = [
      "root"
      "luke"
      "luketandjung"
    ];
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
    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dms-cli = {
      url = "github:AvengeMedia/danklinux";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dankMaterialShell = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.dgop.follows = "dgop";
      inputs.dms-cli.follows = "dms-cli";
    };
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
      dankMaterialShell,
      ...
    }:
    let
      sharedHomeModules = [
        zen-browser.homeModules.beta
        spicetify-nix.homeManagerModules.spicetify
        dankMaterialShell.homeModules.dankMaterialShell.default
      ];
    in
    {
      nixosConfigurations.Lukes-Mac-air = import ./hosts/Lukes-Mac-air {
        inherit inputs sharedHomeModules;
      };

      darwinConfigurations.Lukes-Mac-mini = import ./hosts/Lukes-Mac-mini {
        inherit inputs sharedHomeModules;
      };
    };
}
