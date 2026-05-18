{ inputs, sharedHomeModules, ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-bak";
    extraSpecialArgs = { inherit inputs; };
    users.luke = ../home.nix;
    sharedModules = sharedHomeModules;
  };
}
