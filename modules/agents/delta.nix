flake@{ inputs, ... }:
{
  modules.home.delta-implementation =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      cfg = config.programs.zed-delta;
      sharedMcp = flake.config.agentSupport.renderMcp {
        inherit lib pkgs;
        servers = config.programs.agent-mcp.servers;
      };
    in
    {

      options.programs.zed-delta = {
        skills.enable = lib.mkEnableOption "shared personal skills for Delta, without installing the app";
        context.enable = lib.mkEnableOption "shared personal AGENTS.md instructions for Delta";
      };

      config = {
        home.packages = lib.mkIf cfg.skills.enable (
          [
            (flake.config.builders.effect_solutions pkgs)
          ]
          ++ sharedMcp.packagesFor "delta"
        );

        xdg.configFile."agent-mcp/delta-setup.md" = lib.mkIf cfg.skills.enable {
          text = sharedMcp.deltaGuide;
        };

        # Delta reads AGENT.md before AGENTS.md; use the preferred name so an
        # existing fallback AGENTS.md cannot silently shadow the shared rules.
        home.file = lib.mkMerge [
          (lib.mkIf cfg.context.enable {
            ".config/delta/AGENT.md".source = ./pi/context/AGENTS.md;
          })

          # Match Pi's per-skill sources so its realpath-based discovery deduplicates
          # skills visible through both ~/.pi/agent/skills and ~/.agents/skills.
          (lib.mkIf cfg.skills.enable (
            lib.mapAttrs' (
              name: _:
              lib.nameValuePair ".agents/skills/${name}" {
                source = ./shared/skills + "/${name}";
              }
            ) (lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./shared/skills))
          ))
        ];
      };
    };

  modules.home.delta =
    { lib, pkgs, ... }:

    {
      programs.zed-delta.skills.enable = true;
      programs.zed-delta.context.enable = true;

      home.packages =
        lib.optionals
          (builtins.elem pkgs.stdenv.hostPlatform.system [
            "x86_64-linux"
            "aarch64-linux"
          ])
          [
            inputs.delta.packages.${pkgs.stdenv.hostPlatform.system}.delta
          ];
    };
}
