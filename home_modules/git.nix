{
  pkgs,
  ...
}:
{
  programs.git = {
    enable = true;
    package = pkgs.git;
    settings = {
      user = {
        name = "LukeTandjung";
        email = "lukelucus123@gmail.com";
      };
    };

    lfs = {
      enable = true;
      package = pkgs.git-lfs;
    };
  };
}
