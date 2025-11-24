{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  programs.git = {
    enable = true;
    package = pkgs.git.override { withLibSecret = true; };
    settings = {
      user = {
        name = "LukeTandjung";
        email = "lukelucus123@gmail.com";
      };
      credential.helper = "libsecret";
    };
  };
}
