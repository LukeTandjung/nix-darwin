{ pkgs, inputs, ... }:

{
  # List packages installed in system profile
  environment = {
    systemPackages = with pkgs; [
      git
      raycast
      dbeaver-bin
      postman
      notion-app
      typst
      typstyle
      typst-live
      tinymist
      tetex
      rustc
      cargo
    ];
  };

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
    overlays = [
      (final: prev: {
        spotify = prev.spotify.overrideAttrs (oldAttrs: {
          src =
            if (prev.stdenv.isDarwin && prev.stdenv.isAarch64) then
              prev.fetchurl {
                url = "https://web.archive.org/web/20251029235406/https://download.scdn.co/SpotifyARM64.dmg";
                hash = "sha256-0gwoptqLBJBM0qJQ+dGAZdCD6WXzDJEs0BfOxz7f2nQ=";
              }
            else
              oldAttrs.src;
        });
      })
    ];
  };

  fonts.packages = with pkgs; [
    font-awesome
    jetbrains-mono
    ibm-plex
  ];

  system.activationScripts.postActivation.text = ''
    echo "Updated /private/etc/sudoers.d/yabai successfully!"
    su - "$(logname)" -c '${pkgs.skhd}/bin/skhd -r'
  '';

  system.stateVersion = 6;
}
