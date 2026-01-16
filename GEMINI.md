I use nixos. My nix files are in /home/misha/nixos-dotfiles/*

I rebuild via -  sudo nixos-rebuild switch --flake ~/nixos-dotfiles#nixos-btw

.
├── configuration.nix
├── flake.lock
├── flake.nix
├── hardware-configuration.nix
├── home
│   └── modules
│       ├── common
│       │   └── default.nix
│       ├── desktop
│       │   └── default.nix
│       ├── git
│       │   └── default.nix
│       ├── hyprland
│       │   └── default.nix
│       ├── k9s
│       │   └── default.nix
│       ├── nixvim
│       │   └── default.nix
│       ├── shell
│       │   ├── default.nix
│       │   └── ghostty-gruvbox-tabs.css
│       ├── ssh
│       │   └── default.nix
│       └── yazi
│           └── default.nix
├── home.nix
└── templates
    ├── go
    │   └── flake.nix
    ├── python
    │   └── flake.nix
    ├── rust
    │   └── flake.nix
    └── zig
        └── flake.nix

