{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Agent tools
    ast-grep
    fastmod
    fzf
    jq
    ripgrep
    tree
  ];
}
