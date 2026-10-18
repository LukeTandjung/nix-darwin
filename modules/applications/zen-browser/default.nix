{ inputs, ... }:
let
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
in
{
  modules.hjem.zen-browser = { config, pkgs, lib, theme, ... }:
    let
      mac = pkgs.stdenv.hostPlatform.isDarwin;
      system = pkgs.stdenv.hostPlatform.system;
      base = if mac then "Library/Application Support/Zen" else ".config/zen";
      profile = "${config.directory}/${base}/${if mac then "Profiles/" else ""}luke";
      relativeProfile = "${if mac then "Profiles/" else ""}luke";
      unwrapped = (import (inputs.zen-browser + "/default.nix") {
        pkgs = inputs.nixpkgs.legacyPackages.${system};
      }).beta-unwrapped;
      # Bind the wrap function and the policy-applied package separately so the
      # branch below stays a single-line application (Nix's multi-line app
      # indentation rules make the inline form fragile to reformatting).
      wrapFirefox = import (inputs.zen-browser + "/wrap-zen.nix") pkgs.wrapFirefox;
      wrapped = unwrapped.override { inherit policies; };
      browser =
        if mac then
          unwrapped.overrideAttrs (old: {
            # Only adjust the external launcher; keep the signed .app untouched.
            postInstall = (old.postInstall or "") + ''
              ${pkgs.gnused}/bin/sed -i 's|Applications/Home Manager Apps/|Applications/Nix User Apps/|g' "$out/bin/zen-beta"
            '';
          })
        else wrapFirefox wrapped { icon = "zen-browser"; };
      preferences = {
        "zen.view.window.scheme" = 0;
        "zen.welcome-screen.seen" = true;
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "font.name.monospace.x-western" = theme.font;
        "font.name.sans-serif.x-western" = theme.font;
        "font.name.serif.x-western" = theme.font;
        "reader.color_scheme" = "custom";
        "reader.custom_colors.background" = theme.colors.base00;
        "reader.custom_colors.foreground" = theme.colors.base05;
        "reader.custom_colors.selection-highlight" = theme.colors.base04;
        "reader.custom_colors.unvisited-links" = theme.colors.base0D;
        "reader.custom_colors.visited-links" = theme.colors.base0E;
      };
      profiles = (pkgs.formats.ini { }).generate "zen-profiles.ini" {
        General = { StartWithLastProfile = 1; Version = 2; };
        Profile0 = { Default = 1; IsRelative = 1; Name = "luke"; Path = relativeProfile; };
      };
    in
    {
      packages = [ browser ];
      files = {
        "${base}/profiles.ini".source = profiles;
        "${base}/${relativeProfile}/user.js".text = preferences
          |> lib.mapAttrsToList (key: value: "user_pref(${builtins.toJSON key}, ${builtins.toJSON value});")
          |> lib.concatStringsSep "\n";
        "${base}/${relativeProfile}/chrome/userChrome.css".text = theme.render ./userChrome.css.mustache { };
        "${base}/${relativeProfile}/chrome/userContent.css".text = theme.render ./userContent.css.mustache { };
      } // lib.optionalAttrs (!mac) {
        ".zen/profiles.ini" = { source = profiles; clobber = true; };
        ".zen/luke".source = profile;
      };
      # Zen owns mutable session data and pins; Hjem only supplies preferences and styles.
    };

  modules.darwin.zen-browser = {
    system.defaults.CustomUserPreferences."app.zen-browser.zen" = policies // {
      EnterprisePoliciesEnabled = true;
    };
  };
}
