{ inputs, sharedHomeModules, ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    users.luketandjung = ../home.nix;
    sharedModules = sharedHomeModules;
  };
}
