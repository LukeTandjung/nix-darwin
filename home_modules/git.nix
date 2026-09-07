{
  pkgs,
  ...
}:
{
  programs.gh = {
    enable = true;
    settings.git_protocol = "ssh";
    gitCredentialHelper.enable = true;
  };

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
