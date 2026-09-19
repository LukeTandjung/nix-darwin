{config, lib, ...}: {
  # Keep the runtime credential path stable across activations.
  users.users.luke.uid = lib.mkDefault 1000;
  nix = {
    # Read the session token exported from KeePassXC, including root builds.
    extraOptions = ''
      !include /run/user/${toString config.users.users.luke.uid}/nix-github/token.conf
    '';
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
