flake@{ inputs, ... }:
let
  recipe =
    {
      lib,
      buildNpmPackage,
      fetchFromGitHub,
      fd,
      ripgrep,
      nodejs,
      poppler-utils,
      makeWrapper,
    }:

    let
      # Vendored snapshots of the model catalog APIs consumed by packages/ai's
      # generate-models script. The script normally fetches these at build time,
      # which is both non-reproducible and blocked by the Nix sandbox. Keep these
      # snapshots in-tree so rebuilds do not depend on mutable live API responses.
      modelsDevData = ./pi/model-catalogs/models-dev-api.json;
      modelsDevDecision = ./pi/model-catalogs/models-dev-decision.json;
      nvidiaModels = ./pi/model-catalogs/nvidia-models.json;
      openrouterModels = ./pi/model-catalogs/openrouter-models.json;
      openrouterModelsImage = ./pi/model-catalogs/openrouter-models-image.json;
      openrouterModelsDecisions = ./pi/model-catalogs/openrouter-models-decisions.json;
      aiGatewayModels = ./pi/model-catalogs/ai-gateway-models.json;
      radiusConfig = ./pi/model-catalogs/radius-config.json;

      # Reads like `await fetch(...)` but from a store path.
      localResponse =
        path: ''new Response(await import("node:fs").then((m) => m.readFileSync("${path}", "utf8")))'';
    in
    buildNpmPackage {
      pname = "pi";
      version = "1.3.0-unstable-2026-10-16";

      src = fetchFromGitHub {
        owner = "earendil-works";
        repo = "pi";
        rev = "8efd314fa3d3232ce197d8d7a6a5660530b9d83e";
        hash = "sha256-GeubA8WHmtdtUAAjgxXi66ueIN6LQtJ5NGPVnVQayDU=";
      };

      npmDepsHash = "sha256-+gFyvrhkCsF99oNvs0gBmLXnDW0hWnZI/wFId7UbI6Q=";

      # Point the script's catalog fetches at the pinned snapshots.
      postPatch = ''
        substituteInPlace packages/ai/scripts/generate-models.ts \
          --replace-fail \
            'const response = await fetch("https://models.dev/api.json");' \
            'const response = ${localResponse modelsDevData};' \
          --replace-fail \
            'const response = await fetch("https://models.dev/models.json?type=decision");' \
            'const response = ${localResponse modelsDevDecision};' \
          --replace-fail \
            'const response = await fetch(`''${NVIDIA_BASE_URL}/models`);' \
            'const response = ${localResponse nvidiaModels};' \
          --replace-fail \
            'const response = await fetch(`https://openrouter.ai/api/v1/models''${query}`);' \
            'const response = new Response(await import("node:fs").then((m) => m.readFileSync(({ "": "${openrouterModels}", "?output_modalities=image": "${openrouterModelsImage}", "?output_modalities=decisions": "${openrouterModelsDecisions}" }[query] || "${openrouterModels}"), "utf8")));' \
          --replace-fail \
            'const response = await fetch(`''${AI_GATEWAY_MODELS_URL}/models`);' \
            'const response = ${localResponse aiGatewayModels};' \
          --replace-fail \
            'const config = await loadRadiusGatewayConfig(DEFAULT_RADIUS_GATEWAY);' \
            'const config = await (${localResponse radiusConfig}).json();'
      '';

      makeCacheWritable = true;

      # Skip lifecycle scripts during install — the monorepo includes packages (e.g. web-ui)
      # with native deps (canvas/pixman) that we don't need for the CLI.
      npmFlags = [ "--ignore-scripts" ];

      # Generate catalog data from the pinned snapshots, then use upstream's offline
      # build to compile workspaces in dependency order and copy their runtime assets.
      preBuild = ''
        npm --prefix packages/ai run generate-models
        npm run build:offline
      '';
      dontNpmBuild = true;

      # Monorepo root is a private package; skip the default npm pack-and-install.
      dontNpmInstall = true;

      nativeBuildInputs = [ makeWrapper ];

      installPhase = ''
        runHook preInstall

        # Prune dev deps to avoid shipping tsgo, biome, etc.
        npm prune --omit=dev --offline

        # Copy the workspace tree. Symlinks in node_modules (e.g. @earendil-works/pi-ai ->
        # ../../packages/ai) remain valid because the relative directory structure is preserved.
        mkdir -p $out/lib/pi-mono
        cp -r node_modules packages $out/lib/pi-mono/

        mkdir -p $out/bin
        makeWrapper ${nodejs}/bin/node $out/bin/pi \
          --add-flags "$out/lib/pi-mono/packages/coding-agent/dist/cli.js" \
          --prefix PATH : ${
            lib.makeBinPath [
              fd
              ripgrep
              nodejs
              poppler-utils
            ]
          } \
          --set PI_SKIP_VERSION_CHECK 1

        runHook postInstall
      '';

      # Exercise the installed CLI so missing runtime assets fail the build.
      doInstallCheck = true;
      installCheckPhase = ''
        runHook preInstallCheck

        HOME=$(mktemp -d) $out/bin/pi --version

        runHook postInstallCheck
      '';

      meta = {
        description = "A terminal-based coding agent with multi-model support";
        homepage = "https://github.com/earendil-works/pi";
        changelog = "https://github.com/earendil-works/pi/releases";
        license = lib.licenses.mit;
        platforms = lib.platforms.all;
        mainProgram = "pi";
      };
    };
in
{
  builders.pi = pkgs: pkgs.callPackage recipe { };
  perSystem = { pkgs, ... }: { packages.pi = flake.config.builders.pi pkgs; };

  modules.hjem.pi-implementation =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      cfg = config.programs.pi;
      jsonFormat = pkgs.formats.json { };
      sharedMcp = flake.config.agentSupport.renderMcp {
        inherit lib pkgs;
        servers = config.programs.agent-mcp.servers;
      };
      pathOrLines = lib.types.either lib.types.path lib.types.lines;

      skillsDir = ./shared/skills;
      promptsDir = ./pi/prompts;
      extensionsDir = ./pi/extensions;
      contextDir = ./pi/context;

      agentBrowser = flake.config.builders.agent_browser pkgs;

      defaultSkills = lib.mapAttrs (name: _: skillsDir + "/${name}") (
        lib.filterAttrs (_: type: type == "directory") (builtins.readDir skillsDir)
      );

      defaultPrompts = lib.mapAttrs (name: _: promptsDir + "/${name}/PROMPT.md") (
        lib.filterAttrs (_: type: type == "directory") (builtins.readDir promptsDir)
      );

      defaultExtensions =
        lib.mapAttrs
          (
            name: type:
            let
              extensionPath = extensionsDir + "/${name}";
              packagePath = extensionPath + "/package.nix";
            in
            if type == "directory" then pkgs.callPackage packagePath { } else extensionPath
          )
          (
            lib.filterAttrs (
              name: type:
              type == "regular"
              || (type == "directory" && builtins.pathExists (extensionsDir + "/${name}/package.nix"))
            ) (builtins.readDir extensionsDir)
          );

      mcpServers = sharedMcp.jsonFor "pi" // cfg.mcp.servers;
      mcpConfig = lib.optionalAttrs cfg.mcp.enable (
        cfg.mcp.extraConfig // lib.optionalAttrs (mcpServers != { }) { inherit mcpServers; }
      );

      # Moves host-provided dependencies (typebox, @earendil-works/*) from
      # dependencies to peerDependencies with a "*" range in installed extension
      # packages. Installed copies of host modules create duplicate runtime
      # instances, which the extension loader reports as warnings.
      extensionPeerDepPatch = pkgs.writeText "pi-extension-peer-dependencies.mjs" ''
        import { existsSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
        import { join } from "node:path";

        const root = join(process.env.HOME, ".pi", "agent", "npm", "node_modules");
        if (!existsSync(root)) process.exit(0);

        const hostProvided = (name) => name === "typebox" || name.startsWith("@earendil-works/");

        const topLevel = readdirSync(root);
        const packages = [
          ...topLevel.filter((entry) => !entry.startsWith("@")),
          ...topLevel
            .filter((entry) => entry.startsWith("@"))
            .flatMap((scope) => readdirSync(join(root, scope)).map((name) => scope + "/" + name)),
        ];

        for (const pkg of packages) {
          const manifestPath = join(root, pkg, "package.json");
          if (!existsSync(manifestPath)) continue;
          const manifest = JSON.parse(readFileSync(manifestPath, "utf8"));
          const dependencies = manifest.dependencies;
          if (!dependencies) continue;
          let changed = false;
          for (const name of Object.keys(dependencies)) {
            if (hostProvided(name)) {
              delete dependencies[name];
              manifest.peerDependencies = { ...(manifest.peerDependencies ?? {}), [name]: "*" };
              changed = true;
            }
          }
          if (changed) {
            writeFileSync(manifestPath, JSON.stringify(manifest, null, 2) + "\n");
            console.log("normalized peer dependencies in " + pkg);
          }
        }
      '';

      # Bare "typebox" (v1.x) is a dependency of the Nix-packaged pi but may not be
      # available when a third-party pi binary (e.g. Architect's bundled copy) loads
      # extensions from ~/.pi/agent/extensions/.  Symlinking the package into a
      # node_modules directory next to the extensions ensures Node resolution finds it
      # regardless of which pi binary is in use.
      typebox = cfg.package + "/lib/pi-mono/node_modules/typebox";
    in
    {

      options.programs.pi = {
        enable = lib.mkEnableOption "pi coding agent";

        package = lib.mkOption {
          type = lib.types.package;
          default = flake.config.builders.pi pkgs;
          description = "The pi package to use.";
        };

        settings = lib.mkOption {
          type = jsonFormat.type;
          default = { };
          description = ''
            Configuration written to {file}`~/.pi/agent/settings.json`.
            See https://github.com/badlogic/pi-mono for available options.
          '';
          example = lib.literalExpression ''
            {
              defaultProvider = "anthropic";
              defaultModel = "claude-sonnet-4-20250514";
              defaultThinkingLevel = "medium";
              theme = "dark";
              compaction = {
                enabled = true;
                reserveTokens = 16384;
                keepRecentTokens = 20000;
              };
              retry = {
                enabled = true;
                maxRetries = 3;
              };
            }
          '';
        };

        mcp = {
          enable = lib.mkEnableOption "MCP support through the built-in mcp extension" // {
            default = true;
          };

          servers = lib.mkOption {
            type = jsonFormat.type;
            default = { };
            description = ''
              MCP servers written under `mcpServers` in `~/.pi/agent/mcp.json`, consumed by
              pi's built-in `mcp` extension. Keep third-party MCP extensions such as
              pi-mcp-adapter out of `settings.packages`; two MCP extensions cannot both
              register `/mcp`.
            '';
            example = lib.literalExpression ''
              {
                chrome-devtools = {
                  command = "npx";
                  args = [ "-y" "chrome-devtools-mcp@latest" ];
                };
              }
            '';
          };

          extraConfig = lib.mkOption {
            type = jsonFormat.type;
            default = { };
            description = "Additional raw configuration merged into `~/.pi/agent/mcp.json`.";
          };
        };

        skills = lib.mkOption {
          type = lib.types.attrsOf pathOrLines;
          default = defaultSkills;
          description = ''
            Skills to install. Each key is a skill name, and the value is either
            a skill directory, a path to a SKILL.md file, or its content as a
            multi-line string. Skill directories are linked in full so references,
            scripts, and assets remain available. Written beneath
            {file}`~/.pi/agent/skills/<name>`.
          '';
          example = lib.literalExpression ''
            {
              my-skill = '''
                # My Skill
                Description of what this skill does.
              ''';
              imported-skill = ./skills/other-skill;
            }
          '';
        };

        prompts = lib.mkOption {
          type = lib.types.attrsOf pathOrLines;
          default = defaultPrompts;
          description = ''
            Prompt templates to install. Each key is a prompt name, and the value
            is either a path to a PROMPT.md file or its content as a multi-line string.
            Written to {file}`~/.pi/agent/prompts/<name>/PROMPT.md`.
          '';
          example = lib.literalExpression ''
            {
              review = '''
                Review the current PR and suggest improvements.
              ''';
              my-prompt = ./prompts/my-prompt/PROMPT.md;
            }
          '';
        };

        extensions = lib.mkOption {
          type = lib.types.attrsOf lib.types.path;
          default = defaultExtensions;
          description = ''
            Extensions to install. Each key is an extension name, and the value
            is a path to the extension file (.ts) or a directory with a Pi extension entrypoint.
            Linked to {file}`~/.pi/agent/extensions/<name>`.
          '';
          example = lib.literalExpression ''
            {
              "my-extension.ts" = ./extensions/my-extension.ts;
            }
          '';
        };

        context = {
          agents = lib.mkOption {
            type = lib.types.nullOr lib.types.lines;
            default = builtins.readFile (contextDir + "/AGENTS.md");
            description = ''
              Content for {file}`~/.pi/agent/AGENTS.md`.
              Project-level instructions for the agent.
            '';
            example = ''
              # Project Instructions
              Always use conventional commits.
            '';
          };

          systemPrompt = lib.mkOption {
            type = lib.types.nullOr lib.types.lines;
            default = null;
            description = ''
              Content for {file}`~/.pi/agent/SYSTEM.md`.
              Replaces the default system prompt entirely.
            '';
          };

          appendSystemPrompt = lib.mkOption {
            type = lib.types.nullOr lib.types.lines;
            default = null;
            description = ''
              Content for {file}`~/.pi/agent/APPEND_SYSTEM.md`.
              Appended to the default system prompt.
            '';
          };
        };
      };

      config = lib.mkIf cfg.enable {
        # Keep the formal-planning toolchain in the user's package profile. The JRE is explicit so Apalache and `java` both work in pi
        # sessions without a system-wide Java installation.
        packages = [
          cfg.package
          (flake.config.builders.effect_solutions pkgs)
          agentBrowser
          pkgs.temurin-jre-bin-17
        ]
        ++ lib.optionals cfg.mcp.enable (sharedMcp.packagesFor "pi");

        files = lib.mergeAttrsList [
          (lib.optionalAttrs (cfg.settings != { }) {
            ".pi/agent/settings.json".source = jsonFormat.generate "settings.json" cfg.settings;
          })

          (lib.optionalAttrs (mcpConfig != { }) {
            ".pi/agent/mcp.json".source = jsonFormat.generate "mcp.json" mcpConfig;
          })

          (lib.mapAttrs' (
            name: value:
            if builtins.isString value && !builtins.pathExists value then
              lib.nameValuePair ".pi/agent/skills/${name}/SKILL.md" { text = value; }
            else if builtins.pathExists (value + "/SKILL.md") then
              lib.nameValuePair ".pi/agent/skills/${name}" {
                source = value;
                clobber = true;
              }
            else
              lib.nameValuePair ".pi/agent/skills/${name}/SKILL.md" { source = value; }
          ) cfg.skills)

          (lib.mapAttrs' (
            name: value:
            lib.nameValuePair ".pi/agent/prompts/${name}/PROMPT.md" (
              if builtins.isString value then { text = value; } else { source = value; }
            )
          ) cfg.prompts)

          (lib.mapAttrs' (
            name: value: lib.nameValuePair ".pi/agent/extensions/${name}" { source = value; }
          ) cfg.extensions)

          {
            ".pi/agent/extensions/node_modules/typebox".source = typebox;
          }

          (lib.optionalAttrs (cfg.context.agents != null) {
            ".pi/agent/AGENTS.md".text = cfg.context.agents;
          })

          (lib.optionalAttrs (cfg.context.systemPrompt != null) {
            ".pi/agent/SYSTEM.md".text = cfg.context.systemPrompt;
          })

          (lib.optionalAttrs (cfg.context.appendSystemPrompt != null) {
            ".pi/agent/APPEND_SYSTEM.md".text = cfg.context.appendSystemPrompt;
          })
        ];

        # Keep npm extension packages current after every rebuild, then normalize
        # their manifests. Best effort: an offline rebuild must not fail because
        # of this step.
        activationScripts.updatePiExtensions = ''
          # Darwin user agents can start alongside the Hjem linker.
          for attempt in {1..30}; do
            [ -e "$HOME/.pi/agent/settings.json" ] && break
            sleep 1
          done
          [ -e "$HOME/.pi/agent/settings.json" ] || exit 1
          export PATH="${pkgs.nodejs}/bin:$PATH"
          if ! "${cfg.package}/bin/pi" update --extensions >"$HOME/.pi/agent/extensions-update.log" 2>&1; then
            echo "warning: pi extension update failed; see $HOME/.pi/agent/extensions-update.log" >&2
          fi
          "${pkgs.nodejs}/bin/node" ${extensionPeerDepPatch}
        '';
      };
    };

  modules.hjem.pi =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      programs.pi = {
        enable = true;

        settings = {
          defaultProvider = "openai-codex";
          defaultModel = "gpt-5.6-sol";
          defaultThinkingLevel = "low";
          theme = "dark";
          packages = [
            "git:github.com/lukeramsden/pi-prewalk@v1.1.1"
            "npm:@hicaru/pi-rlm"
            "npm:pi-docparser"
            "npm:pi-autoresearch"
            "npm:@pi-unipi/notify"
            "npm:@juicesharp/rpiv-ask-user-question"
            "npm:pi-agent-browser-native"
          ]
          ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
            "npm:pi-goal-x"
            "npm:pi-web-access"
          ];
          compaction = {
            enabled = true;
            reserveTokens = 16384;
            keepRecentTokens = 20000;
          };
          retry = {
            enabled = true;
            maxRetries = 100;
            maxAgentDelayMs = 60000;
          };
        };

        mcp.enable = true;
      };

      # Written as literal JSON because "$var" is not a valid Nix attribute name.
      #
      # The supernova apiKey uses pi's "!command" syntax: secret-tool reads
      # the entry shared via KeePassXC's Secret Service integration, so the
      # vault stays password+passkey protected and no unlock happens here.
      #
      # Qwen3.8's chat template only accepts enable_thinking plus a graded
      # reasoning_effort of xhigh|medium|low (anything else raises a Jinja
      # exception). pi maps its own thinking levels onto that scale via
      # thinkingLevelMap, so each level changes the actual thinking depth.
      files.".pi/agent/models.json".text = ''
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
                "thinkingFormat": "chat-template",
                "chatTemplateKwargs": {
                  "enable_thinking": { "$var": "thinking.enabled" },
                  "preserve_thinking": true,
                  "reasoning_effort": { "$var": "thinking.effort" }
                }
              },
              "models": [
                {
                  "id": "swift-1.5",
                  "name": "Swift-1.5 27B Uncensored (Local NVFP4 DFlash2)",
                  "reasoning": true,
                  "input": ["text"],
                  "contextWindow": 300000,
                  "maxTokens": 32768,
                  "thinkingLevelMap": {
                    "minimal": null,
                    "low": "low",
                    "medium": "medium",
                    "high": "xhigh"
                  }
                }
              ]
            }
          }
        }
      '';
    };
}
