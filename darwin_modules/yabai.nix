{ pkgs, system, ... }:
{
  services.yabai = {
    enable = true;
    package = pkgs.yabai;
    config = {
      layout = "bsp";
      window_placement = "second_child";
      top_padding = 16;
      bottom_padding = 16;
      left_padding = 16;
      right_padding = 16;
      window_gap = 16;
      mouse_modifier = "cmd";
      focus_follows_mouse = "autoraise";
      menubar_opacity = 0.0;
      window_opacity = "on";
      active_window_opacity = 1.0;
      normal_window_opacity = 0.80;
      external_bar = "all:40:0";
    };
    extraConfig = ''
      yabai -m signal --add event=dock_did_restart action="sudo yabai --load-sa"
      sudo yabai --load-sa
    '';
  };
}
