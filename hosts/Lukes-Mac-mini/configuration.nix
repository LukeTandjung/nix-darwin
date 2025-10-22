{ pkgs, inputs, ... }:

{
  # List packages installed in system profile
  environment = {
    systemPackages = with pkgs; [
      git
      raycast
      dbeaver-bin
      postman
      notion-app
      typst
      typstyle
      typst-live
      tinymist
      tetex
      rustc
      cargo
      brave
    ];
  };

  system.primaryUser = "luketandjung";

  users.users.luketandjung = {
    name = "luketandjung";
    home = "/Users/luketandjung";
  };

  security.sudo.extraConfig = ''
    %staff ALL = (ALL) NOPASSWD: ALL
  '';

  system.defaults.finder.QuitMenuItem = true;

  nixpkgs = {
    hostPlatform = "aarch64-darwin";
    config.allowUnfree = true;
  };

  fonts.packages = with pkgs; [
    font-awesome
    jetbrains-mono
    ibm-plex
  ];

  system.activationScripts.postActivation.text = ''
    echo "Updated /private/etc/sudoers.d/yabai successfully!"
    su - "$(logname)" -c '${pkgs.skhd}/bin/skhd -r'
  '';

  system.stateVersion = 6;
}
