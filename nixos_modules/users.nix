{ pkgs, ... }:

{
  users.users.luke = {
    isNormalUser = true;
    description = "Luke";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;
  };

  # Sudo without password for wheel users
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };
}
