{ ... }:

{
  # fwupd 2.x protects metadata refresh D-Bus calls with polkit. The
  # fwupd-refresh systemd unit runs as the unprivileged fwupd-refresh user, so
  # without this rule the automatic refresh can fail with "Failed to obtain auth"
  # and make `nixos-rebuild switch` exit non-zero after activation.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (
        subject.user == "fwupd-refresh" &&
        (
          action.id == "org.freedesktop.fwupd.get-remotes" ||
          action.id == "org.freedesktop.fwupd.refresh-remote"
        )
      ) {
        return polkit.Result.YES;
      }
    });
  '';
}
