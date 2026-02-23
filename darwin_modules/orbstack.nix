{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    orbstack
  ];
}
