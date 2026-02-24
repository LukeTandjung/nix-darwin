This is my Nix-Darwin dotfiles. There are many like it, but this one is mine.
<img width="1920" height="1080" alt="mac_rice" src="https://github.com/user-attachments/assets/c43ca385-b24b-4a18-8350-43531d7c1efd" />

Most people would rice a minimal Linux distro like Arch or NixOS (NixOS is better if you really want to know).

Not only did I choose to rice my NixOS setup, I also decided to undo the billions of dollars of investment and countless designer manhours Apple has invested into their design system, and riced my Mac. Liquid Glass is overrated anyway.

- **Theme**: Base16 Kanagawa by rebelot.
- **Status Bar**: DankMaterialShell for NixOS, spacebar for OSX
- **Window Tiling Manager**: Hyprland for NixOS and yabai for OSX
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
   - Add `/run/current-system/sw/bin/yabai`
   - Add `/run/current-system/sw/bin/skhd`

3. **Partially Disable SIP** (required for yabai scripting addition)
   - Shut down the Mac
   - Hold the power button until "Loading startup options..." appears
   - Click **Options** > **Continue**, select a user and enter your password
   - Open **Utilities > Terminal** from the menu bar
   - Run:
     ```bash
     csrutil enable --without fs --without debug --without nvram
     ```
   - Reboot

4. **Set nvram boot arg** (required for yabai scripting addition on Apple Silicon)
   ```bash
   sudo nvram boot-args=-arm64e_preview_abi
   ```
   Then **reboot**. After reboot, `sudo yabai --load-sa` should work automatically via the yabai config.

5. **Grant TCC permissions for yabai** (if they don't appear in System Settings UI)
   ```bash
   YABAI=$(which yabai)
   CSREQ=$(codesign -d -r- "$YABAI" 2>&1 | awk -F ' => ' '/designated/{print $2}' | csreq -r- -b /dev/stdout | xxd -p | tr -d '\n')

   for service in kTCCServiceAccessibility kTCCServiceScreenCapture; do
     sudo sqlite3 "/Library/Application Support/com.apple.TCC/TCC.db" \
       "INSERT OR REPLACE INTO access (service,client,client_type,auth_value,auth_reason,auth_version,csreq,indirect_object_identifier_type,indirect_object_identifier,flags,last_modified,boot_uuid,last_reminded) VALUES ('$service','$YABAI',1,2,3,1,X'$CSREQ',0,'UNUSED',0,strftime('%s','now'),'UNUSED',strftime('%s','now'));"
   done
   ```

6. **Create Desktop Workspaces**
   - Open Mission Control (swipe up with three/four fingers or Ctrl+Up)
   - Click the **+** button in the top Spaces bar to add workspaces
   - Optionally enable native space switching in **System Settings > Keyboard > Keyboard Shortcuts > Mission Control > Switch to Desktop 1/2/3/etc.**
