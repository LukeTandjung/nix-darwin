{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Agent tools
    ast-grep
    fastmod
    fzf
    gh
    jq
    ripgrep
    tree

    gdal
  ];
}
