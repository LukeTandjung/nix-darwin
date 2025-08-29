{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  services.skhd = {
    enable = true;
    package = pkgs.skhd;
    config = ''
      cmd - left : yabai -m window --focus west
      cmd - down : yabai -m window --focus south
      cmd - up : yabai -m window --focus north
      cmd - right : yabai -m window --focus east

      cmd + shift - left : yabai -m window --warp west
      cmd + shift - down : yabai -m window --warp south
      cmd + shift - up : yabai -m window --warp north
      cmd + shift - right : yabai -m window --warp east

      cmd - 0x1B : yabai -m window --resize rel:-50:-50
      cmd - 0x18 : yabai -m window --resize rel:50:50

      cmd - 0x12 : yabai -m space --focus 1
      cmd - 0x13 : yabai -m space --focus 2
      cmd - 0x14 : yabai -m space --focus 3
      cmd - 0x15 : yabai -m space --focus 4
      cmd - 0x17 : yabai -m space --focus 5

      cmd + shift - 0x12 : yabai -m window --space 1; yabai -m space --focus 1
      cmd + shift - 0x13 : yabai -m window --space 2; yabai -m space --focus 2
      cmd + shift - 0x14 : yabai -m window --space 3; yabai -m space --focus 3
      cmd + shift - 0x15 : yabai -m window --space 4; yabai -m space --focus 4
      cmd + shift - 0x17 : yabai -m window --space 5; yabai -m space --focus 5

      cmd - 0x0C : open -na kitty
      cmd - 0x0E : kitty --single-instance=no zsh -lc yazi
      cmd - 0x07 : kill $(yabai -m query --windows --window | jq '.pid')
    '';
  };
}
