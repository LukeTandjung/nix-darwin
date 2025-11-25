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
    package = pkgs.git;
    settings = {
      user = {
        name = "LukeTandjung";
        email = "lukelucus123@gmail.com";
      };
    };
  };
}
