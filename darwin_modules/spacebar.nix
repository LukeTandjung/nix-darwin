{ pkgs, system, ... }:
{
  services.spacebar = {
    enable = true;
    package = pkgs.spacebar;
    config = {
      position = "top";
      display = "main";
      height = 36;
      title = "on";
      spaces = "on";
      clock = "on";
      padding_left = 20;
      padding_right = 20;
      spacing_left = 25;
      spacing_right = 15;
      text_font = ''"JetBrains Mono:Regular:12.0"'';
      icon_font = ''"Font Awesome 6 Free:Solid:12.0"'';
      background_color = "0xff1f1f28";
      foreground_color = "0xffdcd7ba";
      power_icon_color = "0xffdcd7ba";
      battery_icon_color = "0xffdcd7ba";
      dnd_icon_color = "0xffdcd7ba";
      clock_icon_color = "0xffdcd7ba";
      power_icon_strip = " ";
      space_icon = "•";
      space_icon_strip = "1 2 3 4 5";
      space_icon_color = "0xff2d4f67";
      clock_icon = "";
      dnd_icon = "";
      clock_format = ''"%d/%m/%y %R"'';
    };
  };
}
