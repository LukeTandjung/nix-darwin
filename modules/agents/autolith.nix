flake@{ inputs, ... }:
let
  recipe =
    {
      pkgs,
      autolithSource,
    }:

    let
      upstreamPkgs = import autolithSource.inputs.nixpkgs {
        system = pkgs.stdenv.hostPlatform.system;
      };
    in
    import "${autolithSource}/nix/package.nix" {
      pkgs = upstreamPkgs;
      src = autolithSource;
    };
  renderMcp =
    {
      lib,
      paddleOcrPackage ? null,
      paddleOcrApproval ? "prompt",
      endpointEnvironmentVariable ? null,
      extraServers ? [ ],
    }:

    let
      approvalKeyword =
        approval:
        {
          prompt = ":prompt";
          read-only = ":read-only";
          allow = ":allow";
          deny = ":deny";
        }
        .${approval};
      quoteTools = tools: lib.concatMapStringsSep " " (tool: "\"${tool}\"") tools;
      renderServer =
        {
          name,
          command,
          approval,
          tools,
          trustedReadOnlyTools ? [ ],
          timeout ? 1800,
          transportExtra ? "",
        }:
        let
          trustedTools = lib.optionalString (
            approval == "read-only" && trustedReadOnlyTools != [ ]
          ) "\n     :trusted-read-only-tools (${quoteTools trustedReadOnlyTools})";
        in
        ''
          (:name "${name}"
           :transport
           (:type :stdio
            :command "${command}"
            :directory :workspace${transportExtra})
           :required-p nil
           :startup-timeout-seconds 15
           :tool-timeout-seconds ${toString timeout}
           :approval ${approvalKeyword approval}${trustedTools}
           :child-tools (${quoteTools tools}))
        '';
      endpointEnvironment = lib.optionalString (
        endpointEnvironmentVariable != null
      ) "\n      :environment ((\"PADDLE_OCR_URL\" :environment \"${endpointEnvironmentVariable}\"))";
      servers = lib.optional (paddleOcrPackage != null) (renderServer {
        name = "paddle-ocr";
        command = "${paddleOcrPackage}/bin/autolith-paddle-ocr-mcp";
        approval = paddleOcrApproval;
        tools = [ "paddle_ocr" ];
        trustedReadOnlyTools = [ "paddle_ocr" ];
        transportExtra = endpointEnvironment;
      });
    in
    ''
      (:version 1
       :servers
       (${lib.concatStringsSep "\n  " (servers ++ extraServers)}))
    '';
in
{
  builders.autolith =
    pkgs:
    recipe {
      inherit pkgs;
      autolithSource = inputs.autolith;
    };
  perSystem = { pkgs, ... }: { packages.autolith = flake.config.builders.autolith pkgs; };

  modules.hjem.autolith-implementation =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      cfg = config.programs.autolith;
      sharedMcp = flake.config.agentSupport.renderMcp {
        inherit lib pkgs;
        servers = config.programs.agent-mcp.servers;
      };
      pathOrLines = lib.types.either lib.types.path lib.types.lines;
      approvalType = lib.types.enum [
        "prompt"
        "read-only"
        "allow"
        "deny"
      ];
      skillsDir = ./shared/skills;
      defaultSkills = lib.mapAttrs (name: _: skillsDir + "/${name}") (
        lib.filterAttrs (_: type: type == "directory") (builtins.readDir skillsDir)
      );
      defaultPackage =
        if builtins.hasAttr pkgs.system inputs.autolith.packages then
          flake.config.builders.autolith pkgs
        else
          throw "Autolith does not provide a package for ${pkgs.system}";
      mcpEnabled = sharedMcp.forClient "autolith" != { };
      mcpConfig = renderMcp {
        inherit lib;
        extraServers = sharedMcp.autolithServers;
      };
      fileValue = value: if builtins.isPath value then { source = value; } else { text = value; };
    in
    {

      options.programs.autolith = {
        enable = lib.mkEnableOption "Autolith";

        package = lib.mkOption {
          type = lib.types.package;
          default = defaultPackage;
          description = "The Autolith package to install.";
        };

        init = lib.mkOption {
          type = lib.types.nullOr pathOrLines;
          default = ./autolith/init.lisp;
          description = "Global executable Autolith initialization source.";
        };

        skills = lib.mkOption {
          type = lib.types.attrsOf pathOrLines;
          default = defaultSkills;
          description = "Autolith skills installed below the global skill root.";
        };

        agents = lib.mkOption {
          type = lib.types.attrsOf pathOrLines;
          default = { };
          description = "Autolith child-agent definitions installed as S-expressions.";
        };

        extraPackages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [
            (flake.config.builders.effect_solutions pkgs)
            pkgs.poppler-utils
            pkgs.imagemagick
            pkgs.typst
          ];
          description = "Packages required by the installed Autolith skills.";
        };

        paddleOcr = {
          enable = lib.mkEnableOption "the local PaddleOCR-VL MCP tool" // {
            default = true;
          };

          package = lib.mkOption {
            type = lib.types.package;
            default = flake.config.builders.autolith_paddle_ocr_mcp pkgs;
            description = "The PaddleOCR-VL MCP server package.";
          };

          approval = lib.mkOption {
            type = approvalType;
            default = "prompt";
            description = "Autolith approval policy for the PaddleOCR MCP server.";
          };

          endpointEnvironmentVariable = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            example = "PADDLE_OCR_URL";
            description = "Optional parent environment variable passed to the OCR server as PADDLE_OCR_URL.";
          };
        };

      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion =
              cfg.paddleOcr.endpointEnvironmentVariable == null
              || builtins.match "[A-Za-z_][A-Za-z0-9_]*" cfg.paddleOcr.endpointEnvironmentVariable != null;
            message = "programs.autolith.paddleOcr.endpointEnvironmentVariable must be a POSIX environment variable name";
          }
        ];

        packages = [ cfg.package ] ++ cfg.extraPackages ++ sharedMcp.packagesFor "autolith";

        # Keep existing PaddleOCR options working, but register the result through
        # the same catalogue as every other server. Explicit shared values win.
        programs.agent-mcp.servers.paddle-ocr = {
          enable = lib.mkDefault cfg.paddleOcr.enable;
          clients = lib.mkDefault [ "autolith" ];
          package = lib.mkDefault cfg.paddleOcr.package;
          envFrom = lib.mkDefault (
            lib.optionalAttrs (cfg.paddleOcr.endpointEnvironmentVariable != null) {
              PADDLE_OCR_URL = cfg.paddleOcr.endpointEnvironmentVariable;
            }
          );
          autolith = {
            approval = lib.mkDefault cfg.paddleOcr.approval;
            startupTimeoutSeconds = lib.mkDefault 15;
            toolTimeoutSeconds = lib.mkDefault 1800;
            childTools = lib.mkDefault [ "paddle_ocr" ];
            trustedReadOnlyTools = lib.mkDefault [ "paddle_ocr" ];
          };
        };

        xdg.config.files = lib.mkMerge [
          (lib.optionalAttrs (cfg.init != null) {
            "autolith/init.lisp" = fileValue cfg.init;
          })

          (lib.mapAttrs' (
            name: value:
            lib.nameValuePair "autolith/skills/${name}" (
              if builtins.isPath value && builtins.pathExists (value + "/SKILL.md") then
                {
                  source = value;
                }
              else
                {
                  target = "autolith/skills/${name}/SKILL.md";
                }
                // fileValue value
            )
          ) cfg.skills)

          (lib.mapAttrs' (
            name: value: lib.nameValuePair "autolith/agents/${name}.sexp" (fileValue value)
          ) cfg.agents)

          (lib.optionalAttrs mcpEnabled {
            "autolith/mcp.sexp".text = mcpConfig;
          })
        ];
      };
    };

  modules.hjem.autolith =
    { ... }:
    {
      programs.autolith.enable = true;
    };
}
