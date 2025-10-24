
{ pkgs, ... }:

{
  nix = {
    settings = {
      # Enable experimental features
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operators"
      ];

      # Trusted users
      trusted-users = [
        "root"
        "luke"
        "@wheel"
      ];
    };

  # Also ensure nixpkgs config allows unfree
  nixpkgs.config.allowUnfree = true;
};
