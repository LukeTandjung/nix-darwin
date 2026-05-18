{ inputs, sharedHomeModules, ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-bak";
    extraSpecialArgs = { inherit inputs; };
    users.luketandjung = ../home.nix;
    sharedModules = sharedHomeModules;
  };
}
