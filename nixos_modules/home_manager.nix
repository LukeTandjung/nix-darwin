{ inputs, sharedHomeModules, ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    users.luke = ../home.nix;
    sharedModules = sharedHomeModules;
  };
}
