flake@{ inputs, ... }:
let
  recipe =
    { lib, stdenv, requireFile, makeWrapper, patchelf, binutils, zsh,
      vulkan-loader, libglvnd, wayland, libxkbcommon, libxcb, glib, gtk3, webkitgtk_4_1,
      libwpe, libwpe-fdo, pipewire, zenity, perf, glib-networking, gsettings-desktop-schemas,
      gst_all_1, undmg }:
    let
      version = "0.9.2";

      archName =
        {
          "x86_64-linux" = "linux-x86_64";
          "aarch64-linux" = "linux-arm64";
          "x86_64-darwin" = "macos-x86_64";
          "aarch64-darwin" = "macos-arm64";
        }
        .${stdenv.hostPlatform.system} or (throw "Unsupported platform: ${stdenv.hostPlatform.system}");

      ext = if stdenv.isDarwin then ".dmg" else ".tar.gz";
      filename = "Tern-${version}-${archName}${ext}";

      # Hashes per platform (update when bumping versions)
      hashes = {
        "linux-x86_64" = "0bwdkw94ycyb2vxmqdf4x6c01yl98pds98bi2x02dk2jw9rgwm5x";
        "linux-arm64" = "1vw64x7c4cj7qndc0yzjc4a0lscpqf6plii114hpbgd2q1d0857m";
        "macos-x86_64" = "03ghax7i7harnzyyb2f7z6r5vq09rfhl1glbrm0is6qsjd48f7ya";
        "macos-arm64" = "0yj1h37h3rpx70lv318q854ri8v7m1ywbciy3hc7jrd9r467g0y0";
      };

      # Tern is an auth-gated closed-beta product and cannot be fetched
      # automatically. requireFile resolves to the artifact already present in
      # the local store (added via nix-prefetch-url); on machines without it the
      # build fails with the instructions below instead of leaking credentials
      # into this repo.
      src = requireFile {
        name = filename;
        sha256 = hashes.${archName};
        message = ''
          Tern is an auth-gated closed-beta product and cannot be fetched automatically.

          1. Download '${filename}' from https://build.stencil.so/tern (via Stencil login).
          2. Add the archive to your local Nix store:

             nix-prefetch-url file://\$HOME/Downloads/${filename}

          3. Re-run your nix build or system rebuild.
        '';
      };

      # Linux-only runtime dependencies. The binary dlopen's WebKitGTK & co
      # at runtime (they do not show up in ldd), so they are wired in via rpath
      # and LD_LIBRARY_PATH.
      runtimeLibs = [
        stdenv.cc.cc.lib
        vulkan-loader
        libglvnd
        wayland
        libxkbcommon
        libxcb
        glib
        gtk3
        webkitgtk_4_1
        libwpe
        libwpe-fdo
        pipewire
      ];

      runtimePrograms = [
        zenity
        glib.bin
        perf
      ];

      webkitRuntimeEnv = [
        "--prefix GIO_EXTRA_MODULES : ${glib-networking}/lib/gio/modules"
        "--prefix XDG_DATA_DIRS : ${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}"
        "--prefix GST_PLUGIN_SYSTEM_PATH_1_0 : ${lib.getLib gst_all_1.gst-plugins-base}/lib/gstreamer-1.0"
      ];

      runtimeLibraryPath = lib.makeLibraryPath runtimeLibs;

      # Use the real login shell, including the user's Hjem-managed startup files.
      loginShell = zsh;

    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "tern";
      inherit version src;

      nativeBuildInputs = [
        makeWrapper
      ]
      ++ lib.optionals stdenv.isLinux [
        patchelf
        binutils
      ]
      ++ lib.optionals stdenv.isDarwin [
        undmg
      ];

      dontConfigure = true;
      dontBuild = true;
      dontPatchELF = true;

      # undmg exposes Tern.app beside the volume's dangling Applications symlink,
      # so the generic unpacker cannot choose one directory as the source root.
      sourceRoot = lib.optionalString stdenv.hostPlatform.isDarwin ".";

      installPhase =
        if stdenv.isDarwin then
          ''
            runHook preInstall

            # The DMG volume root contains a single `Tern` directory with
            # `Tern.app` plus a dangling `Applications` symlink.
            mkdir -p "$out/Applications" "$out/bin"
            cp -R *.app "$out/Applications/"

            makeWrapper "$out/Applications/Tern.app/Contents/MacOS/tern" "$out/bin/tern" \
              --set SHELL ${lib.getExe loginShell}

            runHook postInstall
          ''
        else
          ''
            runHook preInstall

            appDir="$out/opt/tern"
            mkdir -p "$appDir" "$out/bin"
            cp -a . "$appDir/"
            chmod -R u+w "$appDir"

            strip --strip-unneeded "$appDir/tern" || true

            rpath="${runtimeLibraryPath}:\$ORIGIN/../lib:\$ORIGIN"
            patchelf --set-rpath "$rpath" "$appDir/tern"
            patchelf --set-interpreter "${stdenv.cc.bintools.dynamicLinker}" "$appDir/tern"

            makeWrapper "$appDir/tern" "$out/bin/tern" \
              --prefix LD_LIBRARY_PATH : "${runtimeLibraryPath}" \
              --prefix PATH : "${lib.makeBinPath runtimePrograms}" \
              --set SHELL ${lib.getExe loginShell} \
              ${lib.concatStringsSep " " webkitRuntimeEnv}

            runHook postInstall
          '';

      passthru = {
        inherit loginShell;
      };

      meta = {
        description = "Rust-native, Kitty-compatible terminal multiplexer";
        homepage = "https://stencil.so/tern";
        license = lib.licenses.unfree;
        mainProgram = "tern";
        platforms = [
          "x86_64-linux"
          "aarch64-linux"
          "x86_64-darwin"
          "aarch64-darwin"
        ];
        sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
      };
    });
in
{
  builders.tern = pkgs: pkgs.callPackage recipe { };
  perSystem = { pkgs, ... }: { packages.tern = flake.config.builders.tern pkgs; };

  modules.hjem.tern-implementation = { config, lib, pkgs, ... }:
    let
      cfg = config.programs.tern;
      configDir = if pkgs.stdenv.hostPlatform.isDarwin
        then "Library/Application Support/Tern"
        else "${lib.removePrefix "${config.directory}/" config.xdg.config.directory}/tern";
    in
    {
      options.programs.tern = {
        enable = lib.mkEnableOption "Tern app";

        package = lib.mkOption {
          type = lib.types.package;
          default = flake.config.builders.tern pkgs;
          description = "The Tern package to use.";
        };

        settings = lib.mkOption {
          type = (pkgs.formats.json { }).type;
          default = { };
          description = "Declarative Tern settings.json overrides (edit here, not in Preferences).";
        };
      };

      config = lib.mkIf cfg.enable {
        packages = [ cfg.package ];
        files."${configDir}/settings.json".text = builtins.toJSON cfg.settings;
        # Tern watches this directory even before any plugins are installed.
        files."${configDir}/plugins/.keep".text = "";
      };
    };

  modules.hjem.tern = { lib, pkgs, theme, ... }:
    let
      # OMP-format theme, with Tern's terminal palette extension. Keep these
      # colors derived from the same Base16 source as kitty, not a second palette.
      mkTheme = name: variant:
        let
          c = variant.colors;
          ansi =
            (lib.take 8 variant.terminalColors ++ [ variant.palette.base02 ]
              ++ lib.drop 9 variant.terminalColors)
            |> map (color: "#${color}");
        in {
          inherit name;
          vars = c;
          terminal = {
            background = c.base00;
            foreground = c.base05;
            chrome = c.base01;
            widget = c.base01;
            inherit ansi;
          };
          export = { pageBg = c.base00; cardBg = c.base01; infoBg = c.base02; };
          colors = {
            accent = c.base0D;
            border = c.base03;
            borderAccent = c.base0D;
            borderMuted = c.base01;
            success = c.base0B;
            error = c.base08;
            warning = c.base0A;
            muted = c.base04;
            dim = c.base03;
            text = c.base05;
            thinkingText = c.base04;
            selectedBg = c.base03;
            userMessageBg = c.base01;
            userMessageText = c.base05;
            customMessageBg = c.base01;
            customMessageText = c.base05;
            customMessageLabel = c.base0E;
            toolPendingBg = c.base01;
            toolSuccessBg = c.base01;
            toolErrorBg = c.base01;
            toolTitle = c.base05;
            toolOutput = c.base05;
            mdHeading = c.base0D;
            mdLink = c.base0D;
            mdLinkUrl = c.base04;
            mdCode = c.base0B;
            mdCodeBlock = c.base05;
            mdCodeBlockBorder = c.base03;
            mdQuote = c.base04;
            mdQuoteBorder = c.base03;
            mdHr = c.base03;
            mdListBullet = c.base09;
            toolDiffAdded = c.base0B;
            toolDiffRemoved = c.base08;
            toolDiffContext = c.base04;
            syntaxComment = c.base03;
            syntaxKeyword = c.base0E;
            syntaxFunction = c.base0D;
            syntaxVariable = c.base05;
            syntaxString = c.base0B;
            syntaxNumber = c.base09;
            syntaxType = c.base0A;
            syntaxOperator = c.base0C;
            syntaxPunctuation = c.base05;
            thinkingOff = c.base03;
            thinkingMinimal = c.base04;
            thinkingLow = c.base0C;
            thinkingMedium = c.base0D;
            thinkingHigh = c.base0E;
            thinkingXhigh = c.base0F;
            bashMode = c.base0B;
            pythonMode = c.base0A;
            statusLineBg = c.base01;
            statusLineSep = c.base03;
            statusLineModel = c.base0D;
            statusLinePath = c.base05;
            statusLineGitClean = c.base0B;
            statusLineGitDirty = c.base0A;
            statusLineContext = c.base04;
            statusLineSpend = c.base0C;
            statusLineStaged = c.base0B;
            statusLineDirty = c.base0A;
            statusLineUntracked = c.base0C;
            statusLineOutput = c.base04;
            statusLineCost = c.base0E;
            statusLineSubagents = c.base0D;
          };
        };
    in {
      programs.tern = {
        enable = true;
        settings = {
          theme = "Dark";
          theme_dark = "kanagawa-nix";
          theme_light = "kanagawa-light-nix";
          # Native agent surfaces use Kanagawa too, not a program-supplied palette.
          program_colors = false;
          font_family = theme.font;
          font_size = theme.fontSize;
          opacity = 100;
          material = "Solid";
          shell = lib.getExe pkgs.zsh;
          # Preserve the existing Zsh/oh-my-posh prompt rather than replacing it.
          native_prompt = false;
          option_as_alt = "both";
          keymap = "kitty";
          # Package updates and preferences are owned by Nix.
          auto_update = false;
        };
      };
      files.".omp/agent/themes/kanagawa-nix.json".text =
        theme.variants.dark
        |> mkTheme "kanagawa-nix"
        |> builtins.toJSON;
      files.".omp/agent/themes/kanagawa-light-nix.json".text =
        theme.variants.light
        |> mkTheme "kanagawa-light-nix"
        |> builtins.toJSON;
    };
}
