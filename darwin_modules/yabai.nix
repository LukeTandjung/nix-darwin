{ pkgs, ... }:
let
  yabai-head = pkgs.yabai.overrideAttrs (old: rec {
    version = "HEAD-b4bfb51";
    src = pkgs.fetchFromGitHub {
      owner = "koekeishiya";
      repo = "yabai";
      rev = "b4bfb51f1d00b5a2ea13beb37577b517381406fd";
      hash = "sha256-XBJUh2l1DurftKZtved0D4LXe+kQ5od9SfIL6J/ymKI=";
    };
    # HEAD has no precompiled binary — build from source on aarch64
    dontBuild = false;
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.xxd ];
    buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.apple-sdk_15 ];
    # Drop x86_64 arch flags — we only need ARM on aarch64-darwin
    postPatch = ''
      substituteInPlace makefile \
        --replace-fail "-arch x86_64" ""
    '';
    buildPhase = ''
      runHook preBuild
      make install
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      cp ./bin/yabai $out/bin/yabai
      runHook postInstall
    '';
    # Skip version check — HEAD version string won't match
    doInstallCheck = false;
  });
in
{
  environment.etc."sudoers.d/yabai".text = ''
    luketandjung ALL=(root) NOPASSWD: SETENV: ${yabai-head}/bin/yabai --load-sa
  '';

  services.yabai = {
    enable = true;
    package = yabai-head;
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
      menubar_opacity = 1.0;
      window_opacity = "on";
      active_window_opacity = 1.0;
      normal_window_opacity = 0.80;
      external_bar = "all:0:0";
    };
    extraConfig = ''
      yabai -m signal --add event=dock_did_restart action="sudo yabai --load-sa"
      sudo yabai --load-sa

      # Ensure 5 spaces exist
      for _ in $(seq 1 $((5 - $(yabai -m query --spaces | jq length)))); do
        yabai -m space --create
      done
    '';
  };
}
