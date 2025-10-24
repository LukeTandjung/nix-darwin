{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  programs.zen-browser = {
    enable = true;
    # At the time of writing this (24 October 2025), aarch64-darwin machines are experiencing GTK+3 build failures.
    # This package override is necessary to stop this.
    package = lib.mkIf pkgs.stdenv.isDarwin (
      (pkgs.wrapFirefox.override {
        libcanberra-gtk3 = pkgs.libcanberra-gtk2;
      })
        pkgs.firefox-unwrapped
        { }
    );
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
      pinsForce = false;
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
      };
    };
  };
  stylix.targets.zen-browser.profileNames = [ "luke" ];
}
