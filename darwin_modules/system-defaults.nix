{ ... }:
{
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      "com.apple.swipescrolldirection" = false;
    };

    dock = {
      autohide = true;
      showhidden = true;

      mouse-over-hilite-stack = true;

      show-recents = false;
      mru-spaces = false;

      tilesize = 48;
      magnification = false;

      enable-spring-load-actions-on-all-items = true;

      persistent-apps = [
        { app = "/Users/luketandjung/Applications/Home Manager Apps/kitty.app"; }
        { app = "/Applications/Wallper.app"; }
        { app = "/Users/luketandjung/Applications/Home Manager Apps/Zen Browser (Beta).app"; }
        { app = "/Applications/1Password.app"; }
      ];
    };

    CustomSystemPreferences."com.apple.dock" = {
      autohide-time-modifier = 0.0;
      autohide-delay = 0.0;
      expose-animation-duration = 0.0;
      springboard-show-duration = 0.0;
      springboard-hide-duration = 0.0;
      springboard-page-duration = 0.0;

      wvous-tl-corner = 0;
      wvous-tr-corner = 0;
      wvous-bl-corner = 0;
      wvous-br-corner = 0;

      launchanim = 0;
    };
  };
}
