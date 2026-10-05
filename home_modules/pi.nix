{
  config,
  pkgs,
  inputs,
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
      npmCommand = [
        "npm"
        "--prefix"
        "${config.home.homeDirectory}/.pi/npm-global"
      ];
      packages = [
        "npm:@hicaru/pi-rlm"
        "npm:pi-docparser"
        "npm:pi-autoresearch"
        "npm:@pi-unipi/notify"
        "npm:@juicesharp/rpiv-ask-user-question"
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

    mcp = {
      enable = true;
      packageSource = "npm:pi-mcp-adapter@latest";

      settings = {
        toolPrefix = "server";
        idleTimeout = 10;
        directTools = false;
      };

      servers = {
        effect = {
          command = "npx";
          args = [
            "-y"
            "effect-mcp@latest"
          ];
        };

        typst = {
          command = "docker";
          args = [
            "run"
            "--rm"
            "-i"
            "ghcr.io/johannesbrandenburger/typst-mcp:latest"
          ];
        };

        notion = {
          url = "https://mcp.notion.com/mcp";
          auth = "oauth";
        };

      };
    };
  };

  home.file.".pi/agent/models.json".text = builtins.toJSON {
    providers.local-ninfer = {
      baseUrl = "http://127.0.0.1:8080/v1";
      api = "openai-completions";
      apiKey = "none";
      compat = {
        supportsDeveloperRole = false;
        supportsReasoningEffort = true;
        maxTokensField = "max_tokens";
        thinkingFormat = "qwen-chat-template";
      };
      models = [
        {
          id = "swift-1.5";
          name = "Swift-1.5 27B Uncensored (Local NVFP4 DFlash2)";
          reasoning = true;
          input = [ "text" ];
          contextWindow = 180000;
          maxTokens = 32768;
        }
      ];
    };
  };
}
