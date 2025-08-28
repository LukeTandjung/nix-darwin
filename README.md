This is my Nix-Darwin dotfiles. There are many like it, but this one is mine.
<img width="1920" height="1080" alt="mac_rice" src="https://github.com/user-attachments/assets/c43ca385-b24b-4a18-8350-43531d7c1efd" />

Most people would rice a minimal Linux distro like Arch or NixOS (NixOS is better if you really want to know).

I chose to undo the billions of dollars of investment and countless designer manhours Apple has invested into their design system, and riced my Mac. 

- **Theme**: Base16 Kanagawa by rebelot.
- **Status Bar**: spacebar
- **Window Tiling Manager**: yabai
- **Terminal Emulator**: kitty
- **Terminal Multiplexer**: zellij
- **IDE**: Zed and Helix (will transition to Helix as soon as I figure out its keybinds in time...)
- **zsh Styling**: oh-my-posh
- **System-wide Styling**: stylix
- **Wallpapers**: Wallper
- **Program Launcher**: Raycast

To install, you need Nix and Nix-Darwin. It's just a matter of cloning the changes into a repo of your choice, and symlinking appropriately.
For example, if you chose to clone the repo at ~/nix-darwin, then the symlink you would need to create is /etc/nix-darwin -> ~/nix-darwin.
