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

### Manual Steps (Fresh NixOS Install)

Assumes `flake.nix` and `hosts/Lukes-Um790/default.nix` are already configured in the repo.

1. **Get networking up**

   On ethernet, it should just work. Test with:
   ```bash
   ping google.com
   ```
   If you need Wi-Fi:
   ```bash
   sudo systemctl start wpa_supplicant
   wpa_cli
   > add_network 0
   > set_network 0 ssid "YOUR_WIFI_NAME"
   > set_network 0 psk "YOUR_WIFI_PASSWORD"
   > enable_network 0
   > quit
   ```

2. **Find your disk**
   ```bash
   lsblk
   ```
   You'll see your NVMe drive, probably `nvme0n1`.

3. **Partition the disk**
   ```bash
   sudo parted /dev/nvme0n1 -- mklabel gpt
   sudo parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 512MiB
   sudo parted /dev/nvme0n1 -- set 1 esp on
   sudo parted /dev/nvme0n1 -- mkpart primary 512MiB 100%
   ```
   This gives you a 512MB EFI partition and the rest for root.

4. **Format the partitions**
   ```bash
   sudo mkfs.fat -F 32 -n BOOT /dev/nvme0n1p1
   sudo mkfs.ext4 -L nixos /dev/nvme0n1p2
   ```

5. **Mount the partitions**
   ```bash
   sudo mount /dev/disk/by-label/nixos /mnt
   sudo mkdir -p /mnt/boot
   sudo mount /dev/disk/by-label/BOOT /mnt/boot
   ```

6. **Generate hardware config**
   ```bash
   sudo nixos-generate-config --root /mnt
   cp /mnt/etc/nixos/hardware-configuration.nix /tmp/hw-config.nix
   ```

7. **Clone the repo and drop in the hardware config**
   ```bash
   sudo mkdir -p /mnt/home/luke/nix-darwin
   sudo git clone https://github.com/LukeTandjung/nix-darwin.git /mnt/home/luke/nix-darwin
   cp /tmp/hw-config.nix /mnt/home/luke/nix-darwin/hosts/Lukes-Um790/hardware-configuration.nix
   ```

8. **Symlink flake into `/etc/nixos`**
   ```bash
   sudo mkdir -p /mnt/etc/nixos
   sudo ln -s /home/luke/nix-darwin/flake.nix /mnt/etc/nixos/flake.nix
   ```

9. **Stage the hardware config**
   ```bash
   cd /mnt/home/luke/nix-darwin
   git add -A
   ```

10. **Install**
   ```bash
   sudo nixos-install --flake /mnt/home/luke/nix-darwin#Lukes-Um790
   ```

---

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
