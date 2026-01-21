{ sharedHomeModules, ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-bak";
    users.luketandjung = ../home.nix;
    sharedModules = sharedHomeModules;
  };
}
