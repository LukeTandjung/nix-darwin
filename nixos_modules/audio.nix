{ pkgs, ... }:

{
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
  };

  environment.systemPackages = with pkgs; [
    pulseaudio  # For CLI tools like pactl
  ];
}
