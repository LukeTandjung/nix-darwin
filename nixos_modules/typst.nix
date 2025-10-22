{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    typst
    typstyle
    typst-live
    tinymist
    tetex
  ];
}
