flake@{
  inputs,
  lib,
  ...
}:
let
  inherit (lib.attrsets)
    attrNames
    concatMapAttrs
    filterAttrs
    getAttr
    hasAttr
    mapAttrsToList
    optionalAttrs
    ;
  inherit (lib.lists)
    elemAt
    filter
    foldr
    head
    isList
    singleton
    ;
  inherit (lib.trivial)
    const
    importJSON
    warn
    flip
    ;
  inherit (lib.fixedPoints) fix;
  inherit (lib.strings)
    concatStrings
    concatStringsSep
    hasInfix
    isString
    match
    split
    splitString
    ;

  # Adapted from RGBCube/ncc at 1e43f2f396806a789bc528e57314b9386d9aca4f.
  # https://github.com/RGBCube/ncc/blob/1e43f2f396806a789bc528e57314b9386d9aca4f/modules/web-browser.mod.nix
  # Cookie banners and content filtering.
  extensions.consent-o-matic.id = "mdjildafknihdffpkfmmpnpoiajfjnjd";
  extensions.ublock-origin =
    let
      assets = importJSON "${inputs.ublock}/assets/assets.json";

      filterLists =
        (
          assets
          |> filterAttrs (_: spec: (spec.content or null) == "filters" && (spec.group or null) != "regions")
          |> flip removeAttrs [
            "ublock-experimental"
          ]
          |> attrNames
        )
        ++ [
          "TUR-0"
          "user-filters"

          "https://raw.githubusercontent.com/DandelionSprout/adfilt/refs/heads/master/BrowseWebsitesWithoutLoggingIn.txt"
          "https://raw.githubusercontent.com/DandelionSprout/adfilt/refs/heads/master/ClearURLs%20for%20uBo/clear_urls_uboified.txt"
          "https://raw.githubusercontent.com/DandelionSprout/adfilt/refs/heads/master/LegitimateURLShortener.txt"
          "https://raw.githubusercontent.com/yokoffing/filterlists/refs/heads/main/annoyance_list.txt"
          "https://raw.githubusercontent.com/yokoffing/filterlists/refs/heads/main/click2load.txt"
          "https://raw.githubusercontent.com/yokoffing/filterlists/refs/heads/main/privacy_essentials.txt"
        ];

      mkStylesheet =
        hostname: css:
        let
          normalize =
            string:
            split "[[:space:]]+" string |> filter (part: isString part && part != "") |> concatStringsSep " ";
        in
        split ''/\*([^*]|\*+[^*/])*\*+/'' css
        |> filter isString
        |> concatStrings
        |> split ''([^{}]+)[{]([^{}]*)[}]''
        |> filter isList
        |> map (
          rule:
          let
            selector = normalize (head rule);

            declarations =
              elemAt rule 1
              |> splitString ";"
              |> map normalize
              |> filter (declaration: declaration != "")
              |> map (
                declaration:
                if match ".*![[:space:]]*important" declaration == null then
                  "${declaration} !important"
                else
                  declaration
              );
          in
          if declarations == singleton "display: none !important" then
            "${hostname}##${selector}"
          else
            "${hostname}##${selector}:style(${concatStringsSep "; " declarations})"
        );
    in
    {
      id = "blockjmkbacgjkknlgpkjjiijinjdanf";
      preinstalled = true;

      settings.toolbar_pin = "force_pinned";

      policy.userSettings = [
        [
          "suspendUntilListsAreLoaded"
          "true"
        ]
        [
          "userFiltersTrusted"
          "true"
        ]
      ];

      policy.toOverwrite.filterLists =
        filter (name: !(hasInfix "://" name || name == "user-filters" || hasAttr name assets)) filterLists
        |> foldr (name: warn "helium: unknown ublock filter list: ${name}") filterLists;

      policy.toOverwrite.filters = [
        "dolap.com##.fancybox-wrap"
      ]
      # YOUTUBE
      ++ [
        # SHORTS -> WATCH
        ''||youtube.com/shorts/$document,uritransform=/^https:\/\/(?:www\.|m\.)?youtube\.com\/shorts\/([^\/?#]+)/https:\/\/www.youtube.com\/watch?v=\$1/''

        # TODO: Allow youtube embeds without click2load'ing, as they are broken: https://github.com/uBlockOrigin/uBlock-issues/issues/3868
        "@@||youtube.com/embed/$frame"
        "@@||youtube-nocookie.com/embed/$frame"
      ]
      # OLD REDDIT
      ++ [
        "@@||reddit.com/media$document"
        "@@||reddit.com/mod$document"
        "@@||reddit.com/poll$document"
        "@@||reddit.com/settings$document"
        "@@||reddit.com/topics$document"
        "@@||reddit.com/community-points$document"
        "@@||reddit.com/appeal$document"
        "@@||reddit.com/appeals$document"
        "@@||reddit.com/notifications$document"
        "@@||reddit.com/message/compose/$document"
        "@@||reddit.com/mail^$document"
        "@@||reddit.com/answers^$document"
        "@@||reddit.com/r/subreddit^$document"
        ''@@/^https:\/\/\w*\.?reddit\.com\/r\/[A-Za-z0-9_]+\/s\//$document''
        ''@@/^https:\/\/\w*\.?reddit\.com\/.*[?&]new_reddit=true(?:$|[&#])/$document''

        ''||reddit.com/gallery/$document,uritransform=/^https:\/\/(?:www\.|np\.|amp\.|i\.)?reddit\.com\/gallery\/(.*)/https:\/\/old.reddit.com\/comments\/\$1/''
        ''||reddit.com^$document,uritransform=/^https:\/\/(?:www\.|np\.|amp\.|i\.)?reddit\.com\/(?!gallery\/)/https:\/\/old.reddit.com\//''

        "old.reddit.com##:is(#eu-cookie-policy, #redesign-beta-optin-btn)"
      ]
      # MAKE X ANONYMOUS: https://gist.github.com/sin-ack/5a6f7e34e78b6acf971d95808c9331d3
      ++ mkStylesheet "x.com" /* css */ ''
        /* user avatars */
        [data-testid=tweet] .r-1mrc8m9.r-1awozwy {
          display: none;
        }

        [data-testid^="UserAvatar-Container-"] {
          display: none;
        }

        /* don't hide avatars on profile pages */
        a[href$="header_photo"] + div [data-testid^="UserAvatar-Container-"] {
          display: block;
        }

        /* Original username */
        [data-testid="User-Name"] > :nth-child(1) [dir=ltr],
        [data-testid="notification"] > :nth-child(1) [dir=ltr] a {
          display: none;
        }

        /* Anonymous username */
        [data-testid="User-Name"]::before,
        [data-testid="notification"] > :nth-child(1) span[dir=ltr]::before {
          content: "Anonymous";
          opacity: 1;
          font-weight: bold;
          font-family: "TwitterChirp";
        }

        [data-testid="User-Name"]:hover::before {
          text-decoration: underline;
        }

        /* @handle */
        [data-testid="User-Name"] > :nth-child(2) [tabindex="-1"] {
          display: none;
        }

        /* "Replying to" message in tweet box */
        .r-gu64tb button > span {
          font-size: 0;
        }

        .r-136ojw6.r-1wbh5a2 button::after {
          font-size: inherit;
          content: "Anonymous";
          color: inherit;
        }

        /* "Replying to" in tweets and notifs */

        [id^="id__"][dir=ltr] a[dir=ltr] {
          font-size: 0;
        }

        [id^="id__"][dir=ltr] a[dir=ltr]::after {
          font-size: 1rem;
          content: "Anonymous";
          color: inherit;
        }
      '';
    };

  # YOUTUBE
  extensions.dearrow.id = "enamippconapkdmgfgjchkhakpfinmaj";
  extensions.sponsorblock.id = "mnjggcdmjocbbbhaepdhchncahnbgone";

  # VISUALS
  extensions.dark-reader.id = "eimadpbcbfnmbkopoojfekhnkhdbieeh";
  extensions.x-posed.id = "oodhljjldjdhcdopjpmfgbaoibpancfk";

  # Userscript permission must be enabled manually in helium://extensions.
  extensions.violentmonkey.id = "jinjaccalgkegednnccohejagnlnfdag";

  # SERVICES
  extensions.onepassword.id = "aeblfdkhhhdcdjpifhhbdiojplfjncoa";
  extensions.keepassxc-browser = {
    id = "oboonakemofpalcgghocfoadofidjkkk";

    settings.toolbar_pin = "force_pinned";

    policy.settings = fix (settings: {
      autoFillRelevantCredential = true;

      defaultGroup = "Web";
      defaultPasskeyGroup = settings.defaultGroup;

      downloadFaviconAfterSave = true;
      passkeys = true;

      useCompactMode = true;
      useMonochromeToolbarIcon = true;
      usePasswordGeneratorIcons = true;
    });
  };

  policy = {
    # EXTENSIONS
    ExtensionInstallBlocklist = singleton "*";

    ExtensionInstallAllowlist = policy.ExtensionInstallForcelist;
    ExtensionInstallForcelist =
      extensions
      |> filterAttrs (_: extension: !(extension.preinstalled or false))
      |> mapAttrsToList (const <| getAttr "id");

    ExtensionInstallSources = singleton "https://services.helium.imput.net/*";

    ExtensionSettings =
      extensions
      |> concatMapAttrs (
        _: extension: optionalAttrs (extension ? settings) { ${extension.id} = extension.settings; }
      );

    "3rdparty".extensions =
      extensions
      |> concatMapAttrs (
        _: extension: optionalAttrs (extension ? policy) { ${extension.id} = extension.policy; }
      );

    # MISC
    DefaultBrowserSettingEnabled = false;
    AutofillAddressEnabled = true;
    AutofillCreditCardEnabled = false;

    DeveloperToolsAvailability = 1;

    BatterySaverModeAvailability = 0;

    # "Continue where you left off" can't be set declaratively on a consumer machine:
    # - Preference `session.restore_on_startup` is HMAC-tracked, writing it externally trips Chromium's reset popup.
    # - Policy `RestoreOnStartup` is restricted by upstream Chromium to AD-joined / Cloud-Management-enrolled
    #   devices only (anti-hijack mitigation), so the managed plist value is loaded then ignored.
    #
    # TODO: Remove this comment when Helium on MacOS gets a toggle to disable these checks with an environment variable.
    RestoreOnStartup = 1;

    # SEARCH
    DefaultSearchProviderEnabled = true;
    DefaultSearchProviderName = "Google";
    DefaultSearchProviderSearchURL = "https://www.google.com/search?q={searchTerms}";
    DefaultSearchProviderSuggestURL = "https://www.google.com/complete/search?client=chrome&q={searchTerms}";
    SearchSuggestEnabled = true;
  };

  # Stylix's current Chromium target uses this single generated-theme policy:
  # https://github.com/nix-community/stylix/blob/2856c4c6a845b9bec98828ef197abe176e4806bb/modules/chromium/nixos.nix
  # Chromium supports it on Linux AND macOS. Use the same palette as Hjem;
  # platform modules only deploy the policy to the location each OS requires.
  policyFor = pkgs: policy // {
    BrowserThemeColor = (flake.config.styling.forPkgs pkgs).colors.base00;
  };

  preferences = {
    helium.completed_onboarding = true;
    helium.services.user_consented = true;

    helium.browser.layout = 2; # Vertical.
    helium.browser.rounded_frame = true;

    helium.browser.new_tab_next_to_active = false;

    bookmark_bar.show_on_all_tabs = true;
    bookmark_bar.show_tab_groups = true;

    download.prompt_for_download = true; # Ask where to save each time.

    # Incognito access and userscript permissions are set manually in helium://extensions.
    # Writing HMAC-tracked `extensions.settings` externally triggers a reset warning.
  };
in
{
  modules.nixos.helium-browser = { pkgs, ... }: {
    environment.etc."chromium/policies/managed/helium.json".text = builtins.toJSON (policyFor pkgs);
  };

  modules.darwin.helium-browser = { pkgs, ... }:
    let
      managed = { "net.imput.helium" = policyFor pkgs; }
        // lib.mapAttrs' (id: value:
          lib.nameValuePair "net.imput.helium.extensions.${id}" value
        ) policy."3rdparty".extensions;
    in {
      system.defaults.CustomUserPreferences."net.imput.helium" = {
        SUEnableAutomaticChecks = false;
        SUAutomaticallyUpdate = false;
        SUSendProfileInfo = false;
      };
      system.activationScripts.postActivation.text = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (domain: value:
          let plist = pkgs.writeText "${domain}.plist" (lib.generators.toPlist { escape = true; } value);
          in ''
            /usr/bin/install -d -m 0755 '/Library/Managed Preferences'
            /usr/bin/install -m 0644 ${plist} '/Library/Managed Preferences/${domain}.plist'
          ''
        ) managed
      );
    };

  modules.hjem.helium-browser = { config, pkgs, theme, ... }:
    let
      mac = pkgs.stdenv.hostPlatform.isDarwin;
      base = if mac then "Library/Application Support/net.imput.helium" else ".config/net.imput.helium";
      browser = inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default;
      # Original destinations from Luke's Zen pins, not their transient navigation history.
      # Seed once; Helium owns subsequent pin edits and session data.
      pinnedPages = [
        "https://search.nixos.org/packages?channel=unstable"
        "https://search.nixos.org/options?channel=unstable"
        "https://home-manager-options.extranix.com/?release=master"
        "https://options.nix-darwin.uz/?release=master"
        "https://web.whatsapp.com"
        "https://github.com"
        "https://chat.com"
      ];
      initialPreferences = lib.recursiveUpdate preferences {
        pinned_tabs = map (url: { inherit url; }) pinnedPages;
        webkit.webprefs.fonts = lib.genAttrs [ "standard" "serif" "sansserif" "fixed" ] (_: {
          Zyyy = theme.font;
        });
      };
      seed = pkgs.writeText "helium-initial-preferences.json" (builtins.toJSON initialPreferences);
      nativeHost = {
        name = "org.keepassxc.keepassxc_browser";
        description = "KeePassXC browser integration";
        path = if mac
          then "${pkgs.keepassxc}/Applications/KeePassXC.app/Contents/MacOS/keepassxc-proxy"
          else "${pkgs.keepassxc}/bin/keepassxc-proxy";
        type = "stdio";
        allowed_origins = [ "chrome-extension://${extensions.keepassxc-browser.id}/" ];
      };
    in {
      packages = [ browser ];
      files."${base}/NativeMessagingHosts/org.keepassxc.keepassxc_browser.json".text = builtins.toJSON nativeHost;

      # Never symlink Preferences into the store or overwrite an existing profile.
      # Atomic no-clobber publication also preserves regular and dangling symlinks.
      activationScripts.helium-browser = ''
        ${pkgs.python3}/bin/python3 - ${seed} ${lib.escapeShellArg "${config.directory}/${base}/Default/Preferences"} <<'PY'
        import os
        import pathlib
        import sys
        import tempfile

        source, target = map(pathlib.Path, sys.argv[1:])
        if not os.path.lexists(target):
            target.parent.mkdir(parents=True, exist_ok=True)
            fd, temporary = tempfile.mkstemp(prefix=".helium-seed-", dir=target.parent)
            try:
                with os.fdopen(fd, "wb") as output:
                    output.write(source.read_bytes())
                    output.flush()
                    os.fsync(output.fileno())
                try:
                    os.link(temporary, target)
                except FileExistsError:
                    pass
            finally:
                os.unlink(temporary)
        PY
        ${lib.optionalString mac ''
          ${pkgs.defaultbrowser}/bin/defaultbrowser helium
        ''}
        ${lib.optionalString (!mac) ''
          ${pkgs.xdg-utils}/bin/xdg-settings set default-web-browser helium.desktop
          ${lib.concatMapStringsSep "\n" (mime:
            "${pkgs.xdg-utils}/bin/xdg-mime default helium.desktop ${lib.escapeShellArg mime}"
          ) [
            "application/pdf" "application/rdf+xml" "application/rss+xml"
            "application/xhtml+xml" "application/xhtml_xml" "application/xml"
            "image/gif" "image/jpeg" "image/png" "image/webp"
            "text/html" "text/xml" "x-scheme-handler/http" "x-scheme-handler/https"
          ]}
        ''}
      '';
    };
}
