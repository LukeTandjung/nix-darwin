{ ... }:
{
  modules.darwin.system-defaults = { ... }: {
    security.pam.services.sudo_local.touchIdAuth = true;

    system.defaults = {
      NSGlobalDomain = {
        AppleInterfaceStyle = "Dark";
        NSWindowResizeTime = 0.001;
        "com.apple.swipescrolldirection" = false;
      };

      universalaccess.reduceMotion = true;

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
          { app = "/Users/luketandjung/Applications/Nix User Apps/kitty.app"; }
          { app = "/Applications/Wallper.app"; }
          { app = "/Users/luketandjung/Applications/Nix User Apps/Helium.app"; }
          { app = "/Applications/1Password.app"; }
        ];
      };

      trackpad = {
        Clicking = true;
        TrackpadRightClick = true;
      };

      CustomSystemPreferences = {
        # https://rgbcu.be/dump/darwin/reduce-motion-nix-darwin/
        "com.apple.Accessibility".ReduceMotionEnabled = 1;

        "com.apple.dock" = {
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
    };
  };
}
