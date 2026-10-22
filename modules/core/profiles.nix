{ config, ... }:
{
  modules.hjem.default.imports = with config.modules.hjem; [
    home-base
    agents
    quint
    bend-implementation
    bend
    tern-implementation
    tern
    claude-desktop-implementation
    direnv
    helix
    herdr
    keepassxc
    oh-my-posh
    spicetify
    vesktop
    zed-editor
    helium-browser
    zsh
    git
  ];
  modules.nixos.default.imports = with config.modules.nixos; [
    helium-browser
    git
    typst
    rust
    evince
    hjem
    docker
    steam
    solaar
    valent
    kew
    llm
  ];
  modules.darwin.default.imports = with config.modules.darwin; [
    hjem
    homebrew
    orbstack
    postgresql
    rust
    typst
  ];
}
