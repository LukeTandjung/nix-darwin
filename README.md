This is my Nix-Darwin dotfiles. There are many like it, but this one is mine.
<img width="1920" height="1080" alt="mac_rice" src="https://github.com/user-attachments/assets/c43ca385-b24b-4a18-8350-43531d7c1efd" />

Most people would rice a minimal Linux distro like Arch or NixOS (NixOS is better if you really want to know).

Not only did I choose to rice my NixOS setup, I also decided to undo the billions of dollars of investment and countless designer manhours Apple has invested into their design system, and riced my Mac. Liquid Glass is overrated anyway.

- **Theme**: Base16 Kanagawa by rebelot.
- **Status Bar**: DankMaterialShell for NixOS, spacebar for OSX
- **Window Tiling Manager**: Hyprland for NixOS and AeroSpace for OSX
- **Terminal Emulator**: kitty
- **IDE**: Zed and Helix (will transition to Helix as soon as I figure out its keybinds in time...)
- **zsh Styling**: oh-my-posh
- **System-wide Styling**: DankMaterialShell and Stylix for NixOS, just Stylix for OSX
- **Program Launcher**: Raycast

To install, you need Nix and nix-darwin. Clone the repo and symlink appropriately.
For example, if you clone to `~/nix-darwin`, create the symlink `/etc/nix-darwin -> ~/nix-darwin`.

### Manual Steps (Fresh Mac)

These cannot be automated through nix-darwin and must be done once per fresh macOS install.

1. **Install Xcode Command Line Tools**
   ```bash
   xcode-select --install
   ```

2. **Grant Accessibility Permissions**
   - Go to **System Settings > Privacy & Security > Accessibility**
   - Add AeroSpace

3. **Create Desktop Workspaces**
   - Open Mission Control (swipe up with three/four fingers or Ctrl+Up)
   - Click the **+** button in the top Spaces bar to add workspaces
   - Optionally enable native space switching in **System Settings > Keyboard > Keyboard Shortcuts > Mission Control > Switch to Desktop 1/2/3/etc.**
