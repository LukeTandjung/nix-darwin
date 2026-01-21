{ sharedHomeModules, ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-bak";
    users.luke = ../home.nix;
    sharedModules = sharedHomeModules;
  };
}
