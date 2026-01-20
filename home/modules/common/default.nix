{
  pkgs,
  inputs,
  ...
}: let
  zen-browser-wrapped = pkgs.symlinkJoin {
    name = "zen-browser-wrapped";
    paths = [inputs.zen-browser.packages.${pkgs.system}.twilight];
    buildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/zen \
        --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath [
        pkgs.pipewire
        pkgs.pulseaudio
        pkgs.alsa-lib
        pkgs.ffmpeg
      ]}"
    '';
  };
in {
  home.packages =
    (with pkgs; [
      ripgrep
      fish
      go
      yazi
      gopls # LSP (optional)
      gotools # goimports etc.
      gofumpt # formatter
      golangci-lint # meta-linter (optional)
      zoom
      bacon
      nil
      zip
      discord # Discord client
      betterdiscordctl # BetterDiscord management tool
      openvpn # OpenVPN CLI
      openconnect # AnyConnect/GlobalProtect-compatible CLI
      wireguard-tools # wg / wg-quick utilities
      telegram-desktop
      whatsapp-for-linux
      kdePackages.dolphin
      spotify
      nixpkgs-fmt
      inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.nodejs_24
      gcc
      webtorrent_desktop
      gdb
      htop
      postgresql_17 # provides `psql`
      redis # provides `redis-cli`
      apacheKafka
      libreoffice
      wl-clipboard
      wtype
      (rust-bin.nightly.latest.default.override {
        extensions = ["rust-src" "rust-analyzer" "miri"];
        targets = ["x86_64-unknown-linux-gnu"];
      })
      cargo-generate
      ncspot
      glab
      pdftk
      thttpd
      nftables
      jq
      conntrack-tools
      openssl
      openssl.dev
      pkg-config
      grim
      beep
      hiddify-app
      traceroute
      awscli2
      alsa-utils
      nixos-generators
      slurp
      (python3.withPackages (ps: with ps; [rembg]))
      claude-code
      playerctl
      hyprshot
      hyprlock
      hyprcursor
      brightnessctl
      fd
      curlie
      zoxide
      eza
      bat
      fzf
      yandex-cloud
      signal-desktop
      session-desktop
      pavucontrol
      protobuf
      protoc-gen-go
      protoc-gen-go-grpc
      fastfetch
      unzip
      libarchive
      grpcurl
      bind
      nemo
      gnumake
      at
      calcurse
      swtpm
      OVMF
      wev
      curl
      minikube
      kubectl
      kubernetes-helm

      # DevOps/Infrastructure tools
      yamllint
      # ansible-lint  # temporarily disabled due to dependency conflicts
      terraform
      terraform-ls
      packer
      vault
      nomad
      consul

      # Screen recording
      obs-studio
      vlc

      # Python package management
      uv
      xorg.xset
      xorg.mkfontscale
    ])
    ++ [
      # Zig from overlay (latest stable release)
      inputs.zig.packages.${pkgs.system}.default
      # ZLS from unstable (latest available version)
      inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.zls
      # sing-box from unstable (for newer version)
      inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.sing-box
      # Zen Browser from flake
      zen-browser-wrapped
    ];

  home.sessionVariables = {
    K9S_FEATURE_GATE_NODE_SHELL = "true";
    EDITOR = "nvim";
    SHELL = "fish";
    BROWSER = "zen";
    PATH = "$HOME/.local/bin:$HOME/.local/npm-global/bin:$HOME/.cargo/bin:$PATH";
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent";
  };

  xdg.configFile."rustfmt/rustfmt.toml".text = ''
    unstable_features = true
    chain_width = 40
  '';
}
