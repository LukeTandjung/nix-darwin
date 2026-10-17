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
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    rnote-nixpkgs.url = "github:nixos/nixpkgs/9da7f1cf7f8a6e2a7cb3001b048546c92a8258b4";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
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
    codex-desktop-linux = {
      url = "github:ilysenko/codex-desktop-linux";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    # Preserve the agent source revision previously pinned through Emporium.
    autolith.url = "github:LukeTandjung/autolith/5ed208fc2d56053e213dbfacba260e8318870bad";
    delta.url = "github:zed-industries/delta-nix";
    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dankMaterialShell = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dms-plugin-registry = {
      url = "github:AvengeMedia/dms-plugin-registry";
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
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      # Every Nix file in modules/ is a top-level feature module. Importing a
      # feature registers it; core/profiles.nix selects the enabled features.
      imports = builtins.filter (path: inputs.nixpkgs.lib.hasSuffix ".nix" (toString path)) (
        inputs.nixpkgs.lib.filesystem.listFilesRecursive ./modules
      );
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
    };
}
