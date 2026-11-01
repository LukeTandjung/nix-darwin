flake@{ inputs, ... }:
{
  modules.hjem.omp-implementation =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.omp;
      jsonFormat = pkgs.formats.json { };
      yamlFormat = pkgs.formats.yaml { };
      configFile = yamlFormat.generate "omp-config.yml" cfg.settings;
      sharedMcp = flake.config.agentSupport.renderMcp {
        inherit lib pkgs;
        servers = config.programs.agent-mcp.servers;
      };
      pathOrLines = lib.types.either lib.types.path lib.types.lines;

      skillsDir = ./shared/skills;
      promptsDir = ./omp/prompts;
      extensionsDir = ./omp/extensions;
      contextDir = ./omp/context;

      defaultSkills =
        builtins.readDir skillsDir
        |> lib.filterAttrs (_: type: type == "directory")
        |> lib.mapAttrs (name: _: skillsDir + "/${name}");

      defaultPrompts =
        builtins.readDir promptsDir
        |> lib.filterAttrs (_: type: type == "directory")
        |> lib.mapAttrs (name: _: promptsDir + "/${name}/PROMPT.md");

      defaultExtensions =
        builtins.readDir extensionsDir
        |> lib.filterAttrs (
          name: type:
          type == "regular"
          || (
            type == "directory"
            && (
              builtins.pathExists (extensionsDir + "/${name}/package.nix")
              || builtins.pathExists (extensionsDir + "/${name}/index.ts")
              || builtins.pathExists (extensionsDir + "/${name}/index.js")
            )
          )
        )
        |> lib.mapAttrs (
          name: type:
          let
            extensionPath = extensionsDir + "/${name}";
            packagePath = extensionPath + "/package.nix";
          in
          if type == "directory" && builtins.pathExists packagePath then
            pkgs.callPackage packagePath { }
          else
            extensionPath
        );

      # OMP accepts Pi's MCP format and legacy Pi extension imports.
      mcpServers = sharedMcp.jsonFor "pi" // cfg.mcp.servers;
      mcpConfig = lib.optionalAttrs cfg.mcp.enable (
        cfg.mcp.extraConfig // lib.optionalAttrs (mcpServers != { }) { inherit mcpServers; }
      );
    in
    {
      options.programs.omp = {
        enable = lib.mkEnableOption "OMP coding agent";

        package = lib.mkOption {
          type = lib.types.package;
          default = inputs.omp.packages.${pkgs.stdenv.hostPlatform.system}.default;
          defaultText = lib.literalExpression "inputs.omp.packages.${pkgs.stdenv.hostPlatform.system}.default";
          description = "The OMP package to use.";
        };

        settings = lib.mkOption {
          type = lib.types.nullOr yamlFormat.type;
          default = null;
          description = ''
            Settings written to {file}`~/.omp/agent/config.yml` as a writable
            regular file. OMP can persist runtime changes, but activation replaces
            them with these declared values.
          '';
          example = lib.literalExpression ''
            {
              modelRoles.default = "anthropic/claude-sonnet-4-5";
              defaultThinkingLevel = "medium";
              theme.dark = "titanium";
              compaction.enabled = true;
            }
          '';
        };

        plugins = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "NPM, Git, or marketplace plugin specs installed and updated by OMP.";
        };

        mcp = {
          enable = lib.mkEnableOption "MCP support" // {
            default = true;
          };

          servers = lib.mkOption {
            type = jsonFormat.type;
            default = { };
            description = "Additional MCP servers written to {file}`~/.omp/agent/mcp.json`.";
          };

          extraConfig = lib.mkOption {
            type = jsonFormat.type;
            default = { };
            description = "Additional raw configuration merged into {file}`~/.omp/agent/mcp.json`.";
          };
        };

        skills = lib.mkOption {
          type = lib.types.attrsOf pathOrLines;
          default = defaultSkills;
          description = ''
            Skills to install beneath {file}`~/.omp/agent/skills/<name>`.
            Values may be skill directories, SKILL.md paths, or inline text.
          '';
        };

        prompts = lib.mkOption {
          type = lib.types.attrsOf pathOrLines;
          default = defaultPrompts;
          description = ''
            Prompt templates installed as
            {file}`~/.omp/agent/prompts/<name>/PROMPT.md`.
          '';
        };

        extensions = lib.mkOption {
          type = lib.types.attrsOf lib.types.path;
          default = defaultExtensions;
          description = ''
            Extension files or directories linked to
            {file}`~/.omp/agent/extensions/<name>`.
          '';
        };

        context = {
          agents = lib.mkOption {
            type = lib.types.nullOr lib.types.lines;
            default = builtins.readFile (contextDir + "/AGENTS.md");
            description = "Content for {file}`~/.omp/agent/AGENTS.md`.";
          };

          systemPrompt = lib.mkOption {
            type = lib.types.nullOr lib.types.lines;
            default = null;
            description = "Content for {file}`~/.omp/agent/SYSTEM.md`.";
          };

          appendSystemPrompt = lib.mkOption {
            type = lib.types.nullOr lib.types.lines;
            default = null;
            description = "Content for {file}`~/.omp/agent/APPEND_SYSTEM.md`.";
          };
        };
      };

      config = lib.mkIf cfg.enable {
        packages = [
          cfg.package
          (flake.config.builders.effect_solutions pkgs)
          pkgs.bun
          pkgs.temurin-jre-bin-17
        ]
        ++ lib.optionals cfg.mcp.enable (sharedMcp.packagesFor "pi");

        files = lib.mergeAttrsList [
          (lib.optionalAttrs (mcpConfig != { }) {
            ".omp/agent/mcp.json".source = jsonFormat.generate "mcp.json" mcpConfig;
          })

          (lib.mapAttrs' (
            name: value:
            if builtins.isString value && !builtins.pathExists value then
              lib.nameValuePair ".omp/agent/skills/${name}/SKILL.md" { text = value; }
            else if builtins.pathExists (value + "/SKILL.md") then
              lib.nameValuePair ".omp/agent/skills/${name}" {
                source = value;
                clobber = true;
              }
            else
              lib.nameValuePair ".omp/agent/skills/${name}/SKILL.md" { source = value; }
          ) cfg.skills)

          (lib.mapAttrs' (
            name: value:
            lib.nameValuePair ".omp/agent/prompts/${name}/PROMPT.md" (
              if builtins.isString value then { text = value; } else { source = value; }
            )
          ) cfg.prompts)

          (lib.mapAttrs' (
            name: value: lib.nameValuePair ".omp/agent/extensions/${name}" { source = value; }
          ) cfg.extensions)

          (lib.optionalAttrs (cfg.context.agents != null) {
            ".omp/agent/AGENTS.md".text = cfg.context.agents;
          })

          (lib.optionalAttrs (cfg.context.systemPrompt != null) {
            ".omp/agent/SYSTEM.md".text = cfg.context.systemPrompt;
          })

          (lib.optionalAttrs (cfg.context.appendSystemPrompt != null) {
            ".omp/agent/APPEND_SYSTEM.md".text = cfg.context.appendSystemPrompt;
          })
        ];

        activationScripts = {
          # OMP locks and rewrites this file. A Nix store symlink breaks that,
          # especially on macOS where the lock is a sibling of the real file.
          ompConfig = lib.mkIf (cfg.settings != null) ''
            mkdir -p "$HOME/.omp/agent"
            install -m 600 ${configFile} "$HOME/.omp/agent/config.yml"
          '';

          updateOmpPlugins = ''
            mkdir -p "$HOME/.omp/agent"
            ${lib.concatMapStringsSep "\n" (plugin: ''
              if ! "${cfg.package}/bin/omp" plugin install ${lib.escapeShellArg plugin} >>"$HOME/.omp/agent/plugins-update.log" 2>&1; then
                echo "warning: OMP plugin installation failed for ${plugin}; see $HOME/.omp/agent/plugins-update.log" >&2
              fi
            '') cfg.plugins}
            if ! "${cfg.package}/bin/omp" update --plugins >>"$HOME/.omp/agent/plugins-update.log" 2>&1; then
              echo "warning: OMP plugin update failed; see $HOME/.omp/agent/plugins-update.log" >&2
            fi
          '';
        };
      };
    };

  modules.hjem.omp =
    { pkgs, lib, ... }:
    {
      programs.omp = {
        enable = true;

        settings = {
          modelRoles.default = "kimi-code/k3.1-pro-highspeed";
          defaultThinkingLevel = "low";
          theme.dark = "dark";
          compaction = {
            enabled = true;
            reserveTokens = 16384;
            keepRecentTokens = 20000;
          };
          retry = {
            enabled = true;
            maxRetries = 100;
          };
        };

        plugins = [
          "pi-docparser"
        ];

        mcp.enable = true;
      };

      # OMP accepts JSON as YAML, but models.yml is its native configuration
      # path. The supernova key is read only when OMP resolves the provider.
      files.".omp/agent/models.yml".text = ''
        {
          "providers": {
            "supernova": {
              "name": "Supernova",
              "baseUrl": "https://api.supernova-labs.ai/glm/v1",
              "api": "openai-completions",
              "apiKey": "!secret-tool lookup Title 'SUPERNOVA_API_KEY'",
              "models": [
                {
                  "id": "glm-5.3",
                  "name": "Supernova GLM-5.3",
                  "reasoning": true,
                  "input": ["text"],
                  "contextWindow": 300000,
                  "cost": {
                    "input": 0.63,
                    "output": 1.98,
                    "cacheRead": 0.117,
                    "cacheWrite": 0.63
                  }
                },
                {
                  "id": "glm-5.3-fast",
                  "name": "Supernova GLM-5.3 Fast",
                  "reasoning": true,
                  "input": ["text"],
                  "contextWindow": 300000,
                  "cost": {
                    "input": 2.80,
                    "output": 8.80,
                    "cacheRead": 0.52,
                    "cacheWrite": 2.80
                  }
                }
              ]
            },
            "local-ninfer": {
              "baseUrl": "http://127.0.0.1:8080/v1",
              "api": "openai-completions",
              "apiKey": "none",
              "compat": {
                "supportsDeveloperRole": false,
                "supportsReasoningEffort": true,
                "supportsStrictMode": false,
                "maxTokensField": "max_tokens",
                "thinkingFormat": "qwen-chat-template",
                "qwenTemplateReasoningEffort": true,
                "reasoningEffortMap": {
                  "high": "xhigh"
                }
              },
              "models": [
                {
                  "id": "swift-1.5",
                  "name": "Swift-1.5 27B Uncensored (Local NVFP4 DFlash2)",
                  "reasoning": true,
                  "input": ["text"],
                  "contextWindow": 262144,
                  "maxTokens": 32768,
                  "thinking": {
                    "mode": "effort",
                    "efforts": ["low", "medium", "high"],
                    "requiresEffort": true
                  }
                }
              ]
            }
          }
        }
      '';
    };
}
