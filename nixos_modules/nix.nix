
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

      # Allow unfree packages
      allow-unfree = true;
    };

    # Use nixpkgs from flake
    registry.nixpkgs.flake = pkgs;
  };

  # Also ensure nixpkgs config allows unfree
  nixpkgs.config.allowUnfree = true;
}
