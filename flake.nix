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
      ...
    }:
    let
      inherit (builtins) readDir;
      inherit (nixpkgs.lib) attrsToList const groupBy listToAttrs mapAttrs nameValuePair;

      lib' = nixpkgs.lib.extend (const <| const <| nix-darwin.lib);
      lib  = lib'.extend <| import ./lib inputs;

      hostsByType = readDir ./hosts
        |> mapAttrs (name: const <| import ./hosts/${name} lib)
        |> attrsToList
        |> groupBy ({ value, ... }:
          if value ? class && value.class == "nixos" then
            "nixosConfigurations"
          else
            "darwinConfigurations")
        |> mapAttrs (const listToAttrs);

      hostConfigs = hostsByType.darwinConfigurations // hostsByType.nixosConfigurations
        |> attrsToList
        |> map ({ name, value }: nameValuePair name value.config)
        |> listToAttrs;

    in hostsByType // hostConfigs // {
      inherit inputs lib;
    }; 
}
