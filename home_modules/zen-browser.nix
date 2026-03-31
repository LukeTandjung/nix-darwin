{
  config,
  lib,
  pkgs,
  ...
}:
let
  zenConfigPath = "${config.xdg.configHome}/zen";
in
{
  programs.zen-browser = {
    enable = true;
    policies = {
      AutofillAddressEnabled = true;
      AutofillCreditCardEnabled = false;
      DisableAppUpdate = true;
      DisableFeedbackCommands = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableTelemetry = true;
      DontCheckDefaultBrowser = true;
      NoDefaultBookmarks = true;
      OfferToSaveLogins = false;
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };
    };
    profiles.luke = {
      isDefault = true;
      settings = {
        "zen.welcome-screen.seen" = true;
      };
      pinsForce = true;
      pins = {
        nixos-packages = {
          id = "a1b2c3d4-1111-4444-8888-111111111111";
          title = "NixOS Packages";
          url = "https://search.nixos.org/packages?channel=unstable";
          position = 1;
          isEssential = true;
        };
        nixos-options = {
          id = "a1b2c3d4-2222-4444-8888-222222222222";
          title = "NixOS Options";
          url = "https://search.nixos.org/options?channel=unstable";
          position = 2;
          isEssential = true;
        };
        home-manager-options = {
          id = "a1b2c3d4-3333-4444-8888-333333333333";
          title = "Home Manager Options";
          url = "https://home-manager-options.extranix.com/?release=master";
          position = 3;
          isEssential = true;
        };
        nix-darwin-options = {
          id = "a1b2c3d4-4444-4444-8888-444444444444";
          title = "Nix Darwin Options";
          url = "https://options.nix-darwin.uz/?release=master";
          position = 4;
          isEssential = true;
        };
        whatsapp = {
          id = "a1b2c3d4-5555-4444-8888-555555555555";
          title = "WhatsApp";
          url = "https://web.whatsapp.com";
          position = 5;
          isEssential = true;
        };
        github = {
          id = "a1b2c3d4-6666-4444-8888-666666666666";
          title = "GitHub";
          url = "https://github.com";
          position = 6;
          isEssential = true;
        };
        t3chat = {
          id = "a1b2c3d4-7777-4444-8888-777777777777";
          title = "Claude";
          url = "https://claude.ai";
          position = 7;
          isEssential = true;
        };
      };
    };
  };

  stylix.targets.zen-browser.profileNames = [ "luke" ];

  home.activation.zen-profile-bridge = lib.hm.dag.entryAfter [ "linkGeneration" ] (
    lib.optionalString pkgs.stdenv.isLinux ''
      mkdir -p "$HOME/.zen"

      if [ -e "$HOME/.zen/profiles.ini" ] && [ ! -e "$HOME/.zen/profiles.ini.pre-hm-backup" ]; then
        cp -a "$HOME/.zen/profiles.ini" "$HOME/.zen/profiles.ini.pre-hm-backup"
      fi

      if [ -d "$HOME/.zen/luke" ] && [ ! -L "$HOME/.zen/luke" ]; then
        mv "$HOME/.zen/luke" "$HOME/.zen/luke.pre-hm-backup"
      elif [ -e "$HOME/.zen/luke" ] && [ ! -L "$HOME/.zen/luke" ]; then
        rm -f "$HOME/.zen/luke"
      fi

      ln -sfn "${zenConfigPath}/luke" "$HOME/.zen/luke"

      cat > "$HOME/.zen/profiles.ini" <<'EOF'
[General]
StartWithLastProfile=1
Version=2

[Profile0]
Default=1
IsRelative=1
Name=luke
Path=luke
EOF
    ''
  );
}
