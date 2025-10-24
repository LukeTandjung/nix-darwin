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
    package =
      (pkgs.wrapFirefox.override {
        libcanberra-gtk3 = pkgs.libcanberra-gtk2;
      })
        pkgs.firefox-unwrapped
        { };
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
    };
  };
  stylix.targets.zen-browser.profileNames = [ "luke" ];
}
