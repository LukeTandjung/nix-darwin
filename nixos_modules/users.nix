{ pkgs, ... }:

{
  users.users.luke = {
    isNormalUser = true;
    description = "Luke";
    extraGroups = [ "wheel" "networkmanager" "surface-control" ];
    shell = pkgs.zsh;
  };

  # Even though this option is enabled by HM, this only enables zsh for the user level;
  # we need to enable zsh systemwide. Otherwise, zsh might miss systemwide nix directories.
  programs.zsh.enable = true;

  # Sudo without password for wheel users
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };
}
