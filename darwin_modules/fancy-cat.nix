{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    fancy-cat
  ];
}
