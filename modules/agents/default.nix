{ config, ... }:
{
  # Ordinary module composition: hosts do not select an agents adapter.
  modules.hjem.agents.imports = with config.modules.hjem; [
    agent-tools
    agent-mcp-implementation
    autolith-implementation
    claude-code-implementation
    delta-implementation
    pi-implementation

    agent-mcp
    autolith
    claude-code
    delta
    pi
  ];
}
