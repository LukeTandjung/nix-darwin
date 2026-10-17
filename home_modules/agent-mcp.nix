{ pkgs, ... }:
{
  # REA is supplied by luke-pkgs. Keep personal shared servers here rather than
  # duplicating their commands/URLs in each agent module.
  programs.agent-mcp.servers = {
    typst = {
      package = pkgs.docker-client;
      command = "${pkgs.docker-client}/bin/docker";
      args = [ "run" "--rm" "-i" "ghcr.io/johannesbrandenburger/typst-mcp:latest" ];
    };
    notion = {
      url = "https://mcp.notion.com/mcp";
      # Autolith supports HTTP but has no MCP OAuth login flow. Delta requires
      # manual Settings → MCP registration; Pi and Claude handle their own OAuth.
      clients = [ "pi" "claude-code" "delta" ];
    };
  };
}
