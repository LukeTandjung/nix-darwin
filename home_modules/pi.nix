{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:
let
  pencil = inputs.luke-pkgs.packages.${pkgs.stdenv.hostPlatform.system}.pencil;

  pencilMcpServer = {
    x86_64-linux = "${pencil}/opt/pencil/resources/app.asar.unpacked/out/mcp-server-linux-x64";
    aarch64-linux = "${pencil}/opt/pencil/resources/app.asar.unpacked/out/mcp-server-linux-arm64";
    x86_64-darwin = "${pencil}/Applications/Pencil.app/Contents/Resources/app.asar.unpacked/out/mcp-server-darwin-x64";
    aarch64-darwin = "${pencil}/Applications/Pencil.app/Contents/Resources/app.asar.unpacked/out/mcp-server-darwin-arm64";
  }.${pkgs.stdenv.hostPlatform.system};
in
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
        "npm:pi-docparser"
        "npm:pi-autoresearch"
        "npm:@pi-unipi/notify"
        "npm:@juicesharp/rpiv-ask-user-question"
      ] ++ lib.optionals (!pkgs.stdenv.isDarwin) [
        "npm:pi-web-access"
      ];
      compaction = {
        enabled = true;
        reserveTokens = 16384;
        keepRecentTokens = 20000;
      };
      retry = {
        enabled = true;
        maxRetries = 3;
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

        pencil = {
          command = pencilMcpServer;
          args = [
            "--app"
            "desktop"
          ];
          env = { };
        };
      };
    };
  };
}
