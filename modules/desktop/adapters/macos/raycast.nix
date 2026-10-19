{ inputs, ... }:
{
  modules.darwin.raycast = { pkgs, lib, ... }:
    let
      enable = false;
    in
    {
      environment.systemPackages = lib.optionals enable [ pkgs.raycast ];
      # AeroSpace routes Cmd-R by focused app; Raycast must not also grab it.
      system.defaults.CustomUserPreferences."com.raycast.macos" = {
        raycastGlobalHotkey = "";
      };
    };
}
