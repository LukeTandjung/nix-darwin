{ ... }:
{
  # Shared user-level tools for every harness, on both Linux and macOS.
  modules.hjem.agent-tools = { pkgs, ... }: {
    packages = with pkgs; [
      ast-grep
      fastmod
      fzf
      gh
      jq
      ripgrep
      tree
      mkcert
      bashInteractive
      coreutils
    ];
  };
}
