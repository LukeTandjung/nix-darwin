flake@{ inputs, ... }:
let
  recipe =
    {
      lib,
      stdenv,
      fetchurl,
    }:

    let
      version = "2.1.302";
      baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";

      platforms = {
        "aarch64-darwin" = {
          slug = "darwin-arm64";
          hash = "sha256-UmLOnehiQ/7Q0h7cObJxVV1WeA0BEuKxlEOf4cZmLTc=";
        };
        "x86_64-darwin" = {
          slug = "darwin-x64";
          hash = "sha256-uakTEU9Chw7I44hIyIyFXXP3MYeHHsLhrQW75UAp2aw=";
        };
        "aarch64-linux" = {
          slug = "linux-arm64";
          hash = "sha256-K9T05e1csJlVtJAJj3RTIctUkefqjHUroeO7AQza2xA=";
        };
        "x86_64-linux" = {
          slug = "linux-x64";
          hash = "sha256-YNfrfxL7sopSUz/ovliECXQDViqgLcc5kaAhxwZ+KaU=";
        };
      };

      platform = platforms.${stdenv.hostPlatform.system};
    in
    stdenv.mkDerivation {
      pname = "claude-code";
      inherit version;

      src = fetchurl {
        url = "${baseUrl}/${version}/${platform.slug}/claude";
        inherit (platform) hash;
      };

      dontUnpack = true;
      dontFixup = true;

      installPhase = ''
        runHook preInstall
        install -Dm755 "$src" "$out/bin/claude"
        runHook postInstall
      '';

      meta = {
        description = "Agentic coding tool that lives in your terminal";
        homepage = "https://code.claude.com";
        license = lib.licenses.unfree;
        mainProgram = "claude";
        platforms = builtins.attrNames platforms;
      };
    };
in
{
  builders.claude_code = pkgs: pkgs.callPackage recipe { };
  perSystem = { pkgs, ... }: { packages.claude_code = flake.config.builders.claude_code pkgs; };

  modules.hjem.claude-code-implementation = { config, lib, pkgs, ... }:
    let
      sharedMcp = flake.config.agentSupport.renderMcp {
        inherit lib pkgs;
        servers = config.programs.agent-mcp.servers;
      };
      mcp = (pkgs.formats.json { }).generate "claude-code-mcp.json" {
        mcpServers = lib.mapAttrs (_: server: server // {
          type = if server ? url then "http" else "stdio";
        }) (sharedMcp.jsonFor "claude-code");
      };
      # Keep the existing plugin namespace so saved tool permissions still match.
      manifest = pkgs.writeText "claude-plugin.json" (builtins.toJSON { name = "hm"; });
      plugin = pkgs.runCommand "claude-personal-mcp-plugin" { } ''
        install -Dm644 ${manifest} $out/.claude-plugin/plugin.json
        install -Dm644 ${mcp} $out/.mcp.json
      '';
      skills = lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./shared/skills);
    in {
      options.programs.claude-code.enable = lib.mkEnableOption "Claude Code";
      config = lib.mkIf config.programs.claude-code.enable {
        packages = [
          (flake.config.builders.claude_code pkgs)
          (flake.config.builders.effect_solutions pkgs)
        ] ++ sharedMcp.packagesFor "claude-code";
        files = {
          ".claude/CLAUDE.md".source = ./pi/context/AGENTS.md;
          # Retain the old path to avoid leaving a duplicate personal plugin behind.
          ".claude/skills/claude-code-home-manager".source = plugin;
        } // lib.mapAttrs' (name: _: lib.nameValuePair ".claude/skills/${name}" {
          source = ./shared/skills + "/${name}";
        }) skills;
      };
    };

  modules.hjem.claude-code =
    { ... }:
    {
      programs.claude-code.enable = true;
    };
}
