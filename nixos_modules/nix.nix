{...}: {
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

      allow-import-from-derivation = true;
      extra-substituters = [
        "https://devenv.cachix.org"
      ];
      extra-trusted-public-keys = [
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      ];
    };
  };
  # Also ensure nixpkgs config allows unfree
  nixpkgs.config.allowUnfree = true;
}
