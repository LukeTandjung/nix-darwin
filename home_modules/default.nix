{ configs, pkgs, lib, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
{
  imports = [
    ./btop.nix
    ./direnv.nix
    ./fastfetch.nix
    ./helix.nix
    ./htop.nix
    ./kitty.nix
    ./lazydocker.nix
    ./oh-my-posh.nix
    ./spicetify.nix
    ./vesktop.nix
    ./zed-editor.nix
    ./zen-browser.nix
    ./zsh.nix
    ./yazi.nix
  ] ++ lib.optionals isDarwin [
    ./skhd.nix
  ] ++ lib.optionals isLinux [];
}
