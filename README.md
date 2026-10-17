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

### Configuration layout (dendritic)

Every `.nix` file under `modules/` is a top-level flake-parts module, discovered
recursively by `flake.nix`. Files are organized by feature rather than by
configuration layer:

- `modules/settings/ports/`: the settings adapter contract.
- `modules/settings/adapters/nixos/`: Linux settings and their bundle.
- `modules/settings/adapters/darwin/`: macOS settings and their bundle, including
  Touch ID and reduced motion.
- `modules/settings/shared/`: Nix, SSH and theme modules shared across platforms.
- `modules/services/`: services such as local inference, rather than general
  system settings.
- `modules/desktop/ports/desktop.nix`: the broad desktop contract.
- `modules/desktop/adapters/`: Linux and macOS implementations, with their
  supporting feature modules in platform subfolders.
- `modules/agents/`: ordinary agent harness modules, each owning its build recipe,
  personal settings and user integration. Non-Nix assets live beside the module.
- `modules/agents/tools/` and `shared/`: agent dependencies (including Effect
  Solutions), MCP rendering and shared skills, not a separate package collection.
- `modules/languages/`: Rust, Bend, Quint and Typst, including the Bend and Quint
  build recipes and Quint assets.
- `modules/terminal/`: Tern's build and user integration.
- `modules/applications/`: applications such as Claude Desktop, independent of
  the desktop-environment domain.
- `modules/core/options.nix`: typed, mergeable deferred-module collections.
- `modules/core/profiles.nix`: explicit feature selections, preserving import
  list order. Discovery registers features; it does **not** enable them everywhere.
  Deferred-module nesting can still change merge order relative to upstream
  modules; use explicit ordering priorities for order-sensitive settings.
- `modules/core/home-manager.nix`: shared Home Manager integration and upstream
  application modules. Home Manager remains the home configuration manager.
- `modules/hosts/ports/`: the host constructor contract.
- `modules/hosts/adapters/`: NixOS and Darwin constructors that compose the
  selected settings and desktop with Home Manager.
- `modules/hosts/machines/`: per-machine adapter selections, settings and hardware.
- `assets/`: non-Nix configuration data and images.

Feature modules capture `inputs` from the outer flake-parts scope. Keep `pkgs`,
`lib`, and application `config` inside the relevant NixOS/Darwin/Home Manager
module so they refer to that host's environment. Use an outer alias such as
`flake@{ inputs, ... }` when also accessing top-level `flake.config`.

To add a feature, place a top-level module in its owning domain, define its
lower-level modules, and select them in a profile, domain adapter or host.
Keep package recipes in that module's `let` block. Reusable builders are exposed
as `builders.<name>` functions accepting the consuming host's `pkgs`; the same
module can export a public package through `perSystem.packages`.

Non-Nix assets live beside their owning modules. There is no separate source
or package repository to maintain. Every `.nix` file in `modules/` remains a
top-level dendritic module, including shared helpers.

#### Desktop port and adapters

The desktop is one broad slot, not separate slots for window management, shell,
launcher, or decorations. An implementation is a typed record containing:

- `platform`: `nixos` or `darwin`.
- `system`: a deferred system module.
- `home`: a deferred Home Manager module.

Adapters register complete implementations without enabling them:

- `adapters.desktop.linux`: Hyprland, DMS, greeter/portals, screenshots and
  wallpaper support. Owns the DMS, plugin-registry and dsearch module imports.
- `adapters.desktop.macos`: AeroSpace, JankyBorders and Raycast.

Each host explicitly fills its desktop slot, for example:

```nix
hosts.Lukes-Um790.desktop = config.adapters.desktop.linux;
hosts.Lukes-MacBook-Pro.desktop = config.adapters.desktop.macos;
```

The host constructor imports the selected `system` module and adds `home` to
Home Manager. It rejects adapters from the wrong platform before importing
system settings. Adapter components are no longer enabled by the common
profiles. macOS system defaults, including Touch ID and reduced motion, belong
to the settings adapter rather than the desktop. Applications remain in the
common profiles; theming belongs to settings.

All port, adapter and component files are still top-level dendritic modules.
The contract validates structure and platform compatibility, not desktop feature
parity or runtime behavior. A new adapter only needs to supply the same broad
contract; its programs need not correspond one-to-one with another adapter.

#### Host and settings adapters

Each machine selects three implementations: `adapter` (its NixOS or Darwin
constructor), `settings`, and `desktop`. Constructors reject settings or desktops
for the wrong platform and compose their system and Home Manager modules.
Machine-specific configuration stays under `modules/hosts/machines/<name>/`.

Settings adapters own the platform settings lists and the upstream Stylix module.
Homebrew lives in `modules/applications/homebrew.nix`, including its upstream
nix-homebrew import. Settings do not select a desktop.

#### Ordinary agent and language modules

Ports/adapters are used for hosts, settings and desktops, not imposed on every
concern. Agents and languages are ordinary dendritic modules selected by the
common profiles. `modules/agents/default.nix` composes the Home Manager agent
modules, including shared `agent-tools` CLI dependencies on Linux and macOS.
`modules/agents/tools/cli/default.nix` owns ast-grep, fastmod, fzf, gh, jq,
ripgrep, tree, mkcert, Bash and GNU coreutils. Each agent tool has its own
folder containing its Nix module and any source assets. Homebrew is reserved for the remaining
macOS casks; the shell prefers the Nix profile over leftover Brew installations.
GitHub CLI settings remain with Git. Removing formula declarations does not
uninstall existing Brew packages automatically.
There is no per-host agents slot or agents adapter registry.

The agent modules own Pi, Autolith, Claude Code, Delta skills/context and shared
MCP configuration. Effect Solutions is packaged under `modules/agents/tools/`
because it is an agent dependency. Bend, Tern and Claude Desktop are not agent
harnesses and remain owned by their respective domains. Bend and Tern stay
enabled through the common profile; Claude Desktop stays disabled.

Quint is built and installed independently by `modules/languages/quint.nix`,
including D2 rendering and Java verification support. Build it with
`nix build --no-link .#quint`. Agents do not install a separate Quint bundle.
The shared skills catalogue exposes `quint-lang`, `quint-modeling`,
`quint-execute-spec` and `feature-formal-planning` to Pi, Autolith, Claude Code
and Delta, so the harnesses know how to use the installed language tools.

Agent implementations and package recipes were migrated from the previously
pinned Emporium revision. They no longer import its agent modules or builds.
The Emporium input has been removed, along with unused Bookokrat, LeetGPU and
Pencil module imports and the Terminal Grotesque font.
Autolith now uses a direct, unchanged source pin; Delta's executable still uses
its existing dedicated flake.

The imported code originated at Emporium revision
`2c98880f66fe981e885e67559d6526c4ded46ceb`; its license is retained in
`licenses/EMPORIUM-MIT.txt`, alongside the assets' own provenance notices.
These domain modules are now the source of truth for the migrated tools, not
copies to keep synchronized with Emporium. No build depends on that repository.
Home Manager still handles
user deployment until the separate Hjem migration.

Public build targets remain available, for example `nix build --no-link .#pi`,
`.#bend` or `.#tern`, but their definitions live with their owning features.
Tern retains its authenticated-download requirement and existing hashes.

#### Credentials and Git

Git, GitHub CLI and the Linux runtime GitHub-token bridge are together in
`modules/development/git.nix`. The bridge still reads KeePassXC Secret Service;
no token is stored in the repository or Nix store.

SSH uses keys loaded by KeePassXC into an existing agent, instead of reading a
private key from `~/secrets`. KeePassXC is installed on Linux **and macOS**.
See [the one-time setup instructions](docs/keepassxc-ssh.md) before applying:
the database entry still needs configuring in KeePassXC. SSH integration and
close-to-tray behavior are enabled through Home Manager. Application preferences
are read-only; the database remains writable. No existing key file is deleted.

### Local inference (Lukes-Um790)

`modules/services/llm.nix` runs Swift-1.5 Qwen3.8-27B Uncensored NVFP4
and defines its pinned NInfer package in the same feature. It replaces
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

Assumes `flake.nix` and `modules/hosts/Lukes-Um790.nix` are already configured in the repo.

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
   ```
   Update `modules/hosts/Lukes-Um790-hardware.nix` with the generated settings
   from `/tmp/hw-config.nix`. Keep the outer top-level module wrapper and replace
   the inner `modules.nixos.Lukes-Um790-hardware` module; do not copy the raw
   generated file over the wrapper.

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
