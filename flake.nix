{
  description = "Luke's Nix Darwin/NixOS System Flake";

  nixConfig = {
    experimental-features = [
      "nix-command"
      "flakes"
      "pipe-operators"
    ];
    trusted-users = [
      "root"
      "luke"
      "luketandjung"
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    flatpaks.url = "github:in-a-dil-emma/declarative-flatpak/latest";
    stylix = {
      url = "github:nix-community/stylix/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    leetgpu.url = "github:LukeTandjung/leetgpu_cli_nix";
    orchids.url = "github:LukeTandjung/orchids";
    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dankMaterialShell = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.dgop.follows = "dgop";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      stylix,
      nix-darwin,
      nixos-hardware,
      flatpaks,
      home-manager,
      zen-browser,
      spicetify-nix,
      dankMaterialShell,
      leetgpu,
      orchids,
      ...
    }:
    let
      sharedHomeModules = [
        zen-browser.homeModules.beta
        spicetify-nix.homeManagerModules.spicetify
        leetgpu.homeManagerModules.default
        orchids.homeManagerModules.default
        dankMaterialShell.homeModules.dank-material-shell
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
