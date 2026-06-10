{ pkgs, inputs, ... }:

{

  system.primaryUser = "luketandjung";

  users.users.luketandjung = {
    name = "luketandjung";
    home = "/Users/luketandjung";
  };

  security.sudo.extraConfig = ''
    %staff ALL = (ALL) NOPASSWD: ALL
  '';

  system.defaults.finder = {
    QuitMenuItem = true;
    AppleShowAllFiles = true;
  };

  nixpkgs = {
    hostPlatform = "aarch64-darwin";
    config.allowUnfree = true;
  };

  fonts.packages = [
    inputs.luke-pkgs.packages.${pkgs.stdenv.hostPlatform.system}.terminal_grotesque
  ] ++ (with pkgs; [
    font-awesome
    jetbrains-mono
    ibm-plex
  ]);

  networking.hostName = "Lukes-MacBook-Pro";

  system.stateVersion = 6;
}
