{ ... }:
{
  services.flatpak = {
    enable = true;
    remotes = {
      "flathub" = "https://dl.flathub.org/repo/flathub.flatpakrepo";
    };
    packages = [
      "io.beekeeperstudio.Studio"
    ];
  };
}
