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
    overlays = [
      # Vesktop codesign fix (https://github.com/nixos/nixpkgs/issues/484618)
      (final: prev: {
        vesktop = prev.vesktop.overrideAttrs (old: {
          buildPhase = ''
            runHook preBuild

            pnpm build
            pnpm exec electron-builder \
              --dir \
              -c.asarUnpack="**/*.node" \
              -c.electronDist=${if prev.stdenv.hostPlatform.isDarwin then "." else "electron-dist"} \
              -c.electronVersion=${prev.electron.version} \
              ${prev.lib.optionalString prev.stdenv.hostPlatform.isDarwin "-c.mac.identity=null"}

            runHook postBuild
          '';
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
