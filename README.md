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

### Local inference (Lukes-Um790)

`nixos_modules/llm.nix` runs Swift-1.5 Qwen3.8-27B Uncensored NVFP4
with the pinned NInfer package in `packages/ninfer.nix`. It replaces
llama.cpp and llama-swap, including the old PaddleOCR profile.

- Endpoint: `http://127.0.0.1:8080/v1`; model ID: `swift-1.5`.
- Pi provider: `local-ninfer`. Select the new model in existing Pi sessions.
- Serving capacity: 180,000 tokens per session and a shared 360,000-token KV pool,
  two active requests and one pending request. Startup and two simultaneous
  short requests passed on the RTX 5090 with this pool and the sandbox below.
  Full-length sessions have not been tested; context includes input and output.
- Retained experiment settings:
  NVFP4 KV, DFlash2 with seven draft tokens and optimized proposal head,
  1,024-token prefill chunks.
- Sampling: temperature 1, top-p 0.95, top-k 20, min-p 0,
  presence penalty 1.5, frequency penalty 0; output limit 32,768 tokens.
- CUDA graphs and thinking retention are enabled. Vision, prefix reuse,
  and host context backing are disabled. Normal use keeps the artifact's
  chat template rather than the frozen benchmark template.
- systemd host-memory limits: `MemoryHigh=40G`, `MemoryMax=48G`,
  `MemorySwapMax=0`. These do not cap VRAM; NInfer's explicit KV pool
  controls its KV allocation.
- Filesystem sandboxing: `NoNewPrivileges`, `ProtectSystem=strict`,
  `ProtectHome`, and `PrivateTmp`. NVIDIA devices and the host network
  remain accessible; `PrivateDevices` and `PrivateNetwork` are disabled.

The model is fetched by immutable revision and verified SHA-256 into the
Nix store. The first build downloads approximately 22.78 GB; no weights
are checked into Git. The artifact's [Swift Open License and notices](https://huggingface.co/2beng2/Swift-1.5-Qwen3.8-27B-Uncensored-NVFP4-NInfer/tree/bc5f15343d55337d067756f40dc524ce6508ba1c)
apply, including its commercial-use conditions.

After committing or staging new files, apply from this repository:

```bash
sudo nixos-rebuild switch --flake .#Lukes-Um790
systemctl status ninfer
curl --fail http://127.0.0.1:8080/health
curl --fail http://127.0.0.1:8080/v1/models
```

Switching replaces the running llama-swap service with NInfer, which keeps
the model resident rather than unloading it after llama-swap's idle timeout.
Existing files under `/var/lib/llm/models` are not deleted; remove obsolete
weights separately when rollback is no longer needed.

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
