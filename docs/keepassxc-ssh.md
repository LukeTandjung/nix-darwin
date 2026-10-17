# SSH keys through KeePassXC

KeePassXC is available natively on Linux and macOS. It is a **client of an SSH
agent**, not an SSH-agent replacement. Private keys belong in your encrypted
KeePassXC database; never add them to a Nix expression or this repository.

## What the configuration does

- Installs KeePassXC on both platforms and starts it with your graphical session.
- Linux: uses Home Manager's OpenSSH agent at `$XDG_RUNTIME_DIR/ssh-agent`.
  KeePassXC starts after that service and receives the same socket explicitly.
  The competing NixOS/GCR agents are disabled. Valent inherits the user-session
  socket instead of forcing the old GCR socket.
- macOS: uses the existing Apple launchd agent and its `SSH_AUTH_SOCK`.
  Home Manager does not start a second SSH agent.
- SSH no longer reads `~/secrets/id_ed25519` or default private identity files.
  It uses identities already loaded into the selected agent. Other manually
  loaded identities can also be offered; SSH does not track which application
  loaded a key.
- Home Manager enables SSH-agent integration and minimizes window closes to the
  tray, keeping KeePassXC running. Explicit Quit still exits the application.
- Application preferences are now managed by Home Manager and read-only.
  KeePassXC may report that it cannot save application preferences; change those
  through Nix. Database entries and SSH key attachments remain writable.
- Secret Service remains enabled on Linux for the GitHub-token bridge.

## One-time setup

Do this before relying on the new SSH configuration:

1. Open/unlock your KeePassXC database.
2. SSH Agent integration is enabled declaratively. KeePassXC should use the same
   `SSH_AUTH_SOCK` as your terminal. If an old local socket override exists,
   clear it before applying the managed preferences.
3. Create or edit the entry for your SSH key. Add the private key as a database
   attachment, and select that attachment in the entry's **SSH Agent** settings.
   Supply its passphrase through the entry if required.
4. Enable adding the key on database unlock and removing it on database lock.
5. After applying the Nix configuration, sign out and back in so terminals,
   background services and KeePassXC all receive the current agent environment.
6. Unlock the database, then run `ssh-add -l` to check the public fingerprints.
   Test the appropriate destination, for example `ssh -T git@github.com`.
   GitHub's successful authentication message still reports that shell access
   is unavailable and normally exits with status 1.
7. Lock the database and confirm the key is removed from the agent.

No existing private-key file is deleted or imported automatically. Keep your
backup until the database-based setup works. An empty or locked agent cannot
authenticate with these SSH settings unless another permitted mechanism exists.

If many keys are loaded, a server may reject the connection before reaching the
correct key. A host-specific public-key `IdentityFile` with `IdentitiesOnly yes`
can select the right agent identity without storing a private key on disk.
Confirm-on-use additionally requires a working askpass UI; macOS may require a
third-party askpass program, so it is not enabled automatically here.

## GitHub tokens are separate

SSH Git authentication uses the agent keys. Nix GitHub API access still uses the
existing Linux-only KeePassXC Secret Service token bridge. Both Git settings and
that bridge now live in `modules/development/git.nix`. Its token file remains
runtime-only, with a `0700` directory and `0077` umask. This is not a new macOS
Secret Service integration.

Reference: https://keepassxc.org/docs/ (SSH Agent integration FAQ).
