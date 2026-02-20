{
  config,
  lib,
  pkgs,
  ...
}: let
  throne = pkgs.stdenv.mkDerivation rec {
    pname = "throne";
    version = "1.0.13";

    src = pkgs.fetchurl {
      url = "https://github.com/throneproj/Throne/releases/download/${version}/Throne-${version}-linux-amd64.zip";
      sha256 = "0pb9ds6xhkm8b0ldpk9537j4b7xic66phkcd2p61s89pkxs7zc03";
    };

    nativeBuildInputs = with pkgs; [
      unzip
      autoPatchelfHook
      qt6.wrapQtAppsHook
      makeWrapper
    ];

    buildInputs = with pkgs; [
      qt6.qtbase
      qt6.qtsvg
      qt6.qtwayland
      libGL
      fontconfig
      freetype
      xorg.libX11
      xorg.libxcb
      libxkbcommon
      stdenv.cc.cc.lib
      gtk3
      pango
      cairo
      gdk-pixbuf
      atk
      openssl
    ];

    unpackPhase = ''
      unzip $src
    '';

    installPhase = ''
            mkdir -p $out/bin $out/share/throne
            cp -r Throne/* $out/share/throne/
            chmod +x $out/share/throne/Throne

            cat > $out/bin/throne <<WRAPPER
      #!/bin/sh
      DATA_DIR="\$HOME/.local/share/throne"
      STORE_DIR="$out/share/throne"

      # Copy app to writable location if not present or outdated
      if [ ! -f "\$DATA_DIR/Throne" ] || [ "\$STORE_DIR/Throne" -nt "\$DATA_DIR/Throne" ]; then
          mkdir -p "\$DATA_DIR"
          cp -r "\$STORE_DIR"/* "\$DATA_DIR"/
          chmod -R u+w "\$DATA_DIR"
      fi

      cd "\$DATA_DIR"
      export LD_LIBRARY_PATH="${pkgs.openssl.out}/lib:\$LD_LIBRARY_PATH"
      export SHELL=/run/current-system/sw/bin/bash
      exec "\$DATA_DIR/Throne" "\$@"
      WRAPPER
            chmod +x $out/bin/throne
    '';

    meta = with lib; {
      description = "Cross-platform GUI proxy utility (Nekoray fork)";
      homepage = "https://github.com/throneproj/Throne";
      license = licenses.gpl3;
      platforms = ["x86_64-linux"];
    };
  };
in {
  imports = [
    ./hardware-configuration.nix
  ];

  nixpkgs.config.allowUnfree = true; # or see per-pkg predicate below
  boot.loader.systemd-boot.enable = true;
  boot.kernel.sysctl = {
    "kernel.perf_event_paranoid" = -1;
    "kernel.kptr_restrict" = 0;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos-btw"; # Define your hostname.
  networking.firewall.allowedTCPPorts = [ 19160 ];
  networking.firewall.allowedUDPPorts = [ 19160 ];
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.
  networking.networkmanager.dns = "systemd-resolved";
  networking.networkmanager.plugins = with pkgs; [
    networkmanager-openvpn
    networkmanager-openconnect
  ];
  services.resolved.enable = true;

  time.timeZone = "Europe/Moscow";

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # Add libraries that Claude Code might need
    stdenv.cc.cc.lib
    zlib
    openssl
  ];

  # Set Monday as first day of week
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_TIME = "en_GB.UTF-8";
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
        FastConnectable = true;
        AutoConnect = true;
        ReconnectAttempts = 7;
        ReconnectIntervals = "1, 2, 4, 8, 16, 32, 64";
      };
      Policy = {
        AutoEnable = true;
      };
    };
  };

  # Wayland-friendly environment (system-wide)
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    SDL_VIDEODRIVER = "wayland";
    BROWSER = "zen";
    MOZ_AUDIO_BACKEND = "pulse";
  };

  # Audio / screen-share stack
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # XDG portals (Hyprland portal is key for file pickers, screen share)
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  hardware.graphics.enable = true;

  # Enable WiFi support
  hardware.wirelessRegulatoryDatabase = true;
  hardware.enableRedistributableFirmware = true;

  hardware.uinput.enable = true;

  # For the GUI client
  services.firezone.gui-client = {
    enable = true;
    name = "kts";
  };

  # services.firezone.headless-client = {
  #   enable = true;
  #   apiUrl = "wss://api.vpn.ktsinfra.ru/";
  #   tokenFile = "/etc/firezone/token";
  #   name = "kts"; # optional
  # };

  services.atd.enable = true;

  # Zapret DPI bypass
  services.zapret = {
    enable = true;
    params = [
      "--dpi-desync=fake,disorder2"
      "--dpi-desync-ttl=6"
      "--dpi-desync-fooling=badsum,md5sig"
      "--dpi-desync-split-pos=1"
      "--dpi-desync-any-protocol"
      "--dpi-desync-repeats=6"
    ];
    udpSupport = true;
    udpPorts = ["50000:65535"];
  };

  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = ["systemd"];
    port = 9100;
  };

  services.cadvisor = {
    enable = true;
    port = 8080;
  };

  services.xremap = {
    enable = false;
  };

  # Display/login manager: greetd (simple, Wayland-friendly)
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "Hyprland";
      user = "misha";
    };
  };

  services.displayManager.ly.enable = false;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.misha = {
    isNormalUser = true;
    shell = pkgs.fish;
    packages = with pkgs; [
      tree
    ];
  };

  virtualisation.docker = {
    enable = true; # start docker daemon
    # Optional:
    # enableOnBoot = true;         # default true
    # rootless.enable = true;      # uncomment for rootless mode (see note below)
  };

  # TUN/TAP support for nekoray
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.core.rmem_max" = 134217728;
    "net.core.wmem_max" = 16777216;
    "net.core.rmem_default" = 134217728;
    "net.core.wmem_default" = 16777216;
  };

  # Load TUN module at boot
  boot.kernelModules = ["uinput" "tun"];

  # Waydroid configuration
  virtualisation.waydroid.enable = true;

  # Add user to netdev group for TUN access
  users.users.misha.extraGroups = ["wheel" "video" "audio" "input" "docker" "netdev" "firezone-client"];

  # Sing-box VPN service (temporarily disabled - using throne instead)
  # systemd.services.sing-box = {
  #   description = "Sing-box proxy service";
  #   after = ["network-online.target"];
  #   wants = ["network-online.target"];
  #   wantedBy = ["multi-user.target"];
  #   serviceConfig = {
  #     Type = "simple";
  #     Restart = "always";
  #     RestartSec = "5";
  #     ExecStart = "${pkgs.sing-box}/bin/sing-box run -c /home/misha/sing-box/finland-routing.json";
  #     User = "root";
  #     Group = "root";
  #   };
  # };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  programs.hyprland.enable = true;
  programs.fish.enable = true;
  programs.direnv.enable = true;
  security.polkit.enable = true;

  # Polkit rule for Throne TUN mode
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.policykit.exec" &&
          subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';
  security.sudo.wheelNeedsPassword = false;

  # Enable ssh-agent system service
  programs.ssh.startAgent = true;

  # Auto-connect to bluetooth headset
  systemd.services.bluetooth-auto-connect = {
    description = "Auto-connect to bluetooth headset";
    after = ["bluetooth.service"];
    wants = ["bluetooth.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = "30";
      ExecStart = "${pkgs.writeShellScript "bluetooth-auto-connect" ''
        while true; do
          ${pkgs.bluez}/bin/bluetoothctl connect 80:99:E7:99:A0:FD
          sleep 1
        done
      ''}";
    };
  };

  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    git
    libnotify
    linuxPackages.perf
    xremap
    wl-clipboard
    docker-compose
    typst
    hiddify-app
    throne
    webtorrent_desktop
    qbittorrent
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    dejavu_fonts
    liberation_ttf
    xorg.fontadobe75dpi
    xorg.fontadobe100dpi
    xorg.fontbh100dpi
    xorg.fontbhlucidatypewriter100dpi
    xorg.fontbhlucidatypewriter75dpi
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];
  system.stateVersion = "25.05";
}
