{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
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
    };
  };
  stylix.targets.zen-browser.profileNames = [ "luke" ];
}
