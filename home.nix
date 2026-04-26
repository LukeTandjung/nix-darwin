{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  programs.home-manager.enable = true;

  home = {
    username = if isDarwin then "luketandjung" else "luke";
    homeDirectory = if isDarwin then "/Users/luketandjung" else "/home/luke";
    stateVersion = "26.05";
    packages = [ ];

    # This suppresses the login message that appears for Kitty!
    file.".hushlogin".text = "";

    sessionVariables = {
      EDITOR = "hx";
    }
    // lib.optionalAttrs isDarwin {
      DOCKER_HOST = "unix:///Users/luketandjung/.orbstack/run/docker.sock";
    };
  };

  imports = [
    ./home_modules
  ];
}
