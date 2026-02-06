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
    rnote-nixpkgs.url = "github:nixos/nixpkgs/9da7f1cf7f8a6e2a7cb3001b048546c92a8258b4";
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
    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dankMaterialShell = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dsearch = {
      url = "github:AvengeMedia/danksearch";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-formulae = {
      url = "github:FelixKratz/homebrew-formulae";
      flake = false;
    };
  };

  outputs =
    inputs@{
      zen-browser,
      spicetify-nix,
      dankMaterialShell,
      dsearch,
      leetgpu,
      ...
    }:
    let
      sharedHomeModules = [
        zen-browser.homeModules.beta
        spicetify-nix.homeManagerModules.spicetify
        leetgpu.homeManagerModules.default
        dankMaterialShell.homeModules.dank-material-shell
        dsearch.homeModules.default
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
