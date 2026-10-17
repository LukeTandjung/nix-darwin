{ ... }:
{
  modules.hjem.kitty = { pkgs, theme, ... }: {
    packages = [ pkgs.kitty ];
    xdg.config.files."kitty/kitty.conf".text = ''
      font_family ${theme.font}
      font_size ${toString theme.fontSize}
      macos_option_as_alt yes
      enabled_layouts horizontal
      # Files are Nix-managed; avoid recursively watching store paths.
      auto_reload_config -1
      background_opacity 1
    '' + theme.render ./theme.mustache { };
  };
}
