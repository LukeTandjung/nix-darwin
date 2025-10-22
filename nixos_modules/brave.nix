{ inputs, pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    brave
  ];
}
