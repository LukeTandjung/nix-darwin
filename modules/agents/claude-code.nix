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

  modules.home.claude-code-implementation =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      cfg = config.programs.claude-code;
      sharedMcp = flake.config.agentSupport.renderMcp {
        inherit lib pkgs;
        servers = config.programs.agent-mcp.servers;
      };
    in
    {

      config = lib.mkIf cfg.enable {
        home.packages = [
          (flake.config.builders.effect_solutions pkgs)
        ]
        ++ sharedMcp.packagesFor "claude-code";

        programs.claude-code = {
          package = lib.mkDefault (flake.config.builders.claude_code pkgs);

          mcpServers = lib.mapAttrs (_: lib.mkDefault) (sharedMcp.jsonFor "claude-code");

          # Keep skills and agent instructions in one place for all agents.
          skills = ./shared/skills;
          context = builtins.readFile ./pi/context/AGENTS.md;
        };
      };
    };

  modules.home.claude-code =
    { ... }:
    {
      programs.claude-code.enable = true;
    };
}
