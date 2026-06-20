{
  config,
  lib,
  pkgs,
  ...
}: let
  byedpi = pkgs.stdenv.mkDerivation rec {
    pname = "byedpi";
    version = "0.14.1";

    src = pkgs.fetchFromGitHub {
      owner = "hufrea";
      repo = "byedpi";
      rev = "v${version}";
      sha256 = "sha256-JdL+3ETNxaEtOLUhgLSABL9C8w/EM4Ay37OXU5jLCFA=";
    };

    makeFlags = ["PREFIX=$(out)"];

    installPhase = ''
      mkdir -p $out/bin
      cp ciadpi $out/bin/
    '';

    meta = with lib; {
      description = "Local SOCKS proxy for DPI bypass";
      homepage = "https://github.com/hufrea/byedpi";
      license = licenses.mit;
      platforms = platforms.linux;
    };
  };

  throne = pkgs.stdenv.mkDerivation rec {
    pname = "throne";
    version = "1.1.2";

    src = pkgs.fetchurl {
      url = "https://github.com/throneproj/Throne/releases/download/${version}/Throne-${version}-linux-amd64.zip";
      sha256 = "sha256-GYDlyCyPxyeUtHPxvy5KIGJF/kC8zlLN5h3GBoH0dgM=";
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
      exec ${pkgs.proxychains-ng}/bin/proxychains4 -f ${pkgs.writeText "proxychains.conf" ''
        localnet 127.0.0.0/255.0.0.0
        localnet 10.0.0.0/255.0.0.0
        localnet 172.16.0.0/255.240.0.0
        localnet 192.168.0.0/255.255.0.0
        [ProxyList]
        socks5 127.0.0.1 1080
      ''} "\$DATA_DIR/Throne" "\$@"
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
  codecrafters-cli = pkgs.stdenv.mkDerivation rec {
    pname = "codecrafters-cli";
    version = "53";

    src = pkgs.fetchurl {
      url = "https://github.com/codecrafters-io/cli/releases/download/v${version}/v${version}_linux_amd64.tar.gz";
      sha256 = "sha256-tpHOyEmJIXDUtFTAxnu/z6ZHarOCKzd/qKz89R8qLL0=";
    };

    sourceRoot = ".";

    installPhase = ''
      mkdir -p $out/bin
      cp codecrafters $out/bin/
    '';

    meta = with lib; {
      description = "CodeCrafters CLI to run tests";
      homepage = "https://github.com/codecrafters-io/cli";
      platforms = ["x86_64-linux"];
    };
  };

  # Happ - cross-platform proxy utility built on Xray core (VLESS/Reality,
  # VMess, Trojan, Shadowsocks). Not in nixpkgs; packaged from the upstream
  # .deb. Bundles its own Qt6 + Xray/sing-box, so we only patch the prebuilt
  # ELF binaries against the bundled libs plus a few system libs.
  happ = pkgs.stdenv.mkDerivation rec {
    pname = "happ";
    version = "2.17.1";

    src = pkgs.fetchurl {
      url = "https://github.com/Happ-proxy/happ-desktop/releases/download/${version}/Happ.linux.x64.deb";
      sha256 = "1gm1zjjvfvnmqcsp03x05i9kkidr9i6ccsih4m2zzinlshlybfg5";
    };

    nativeBuildInputs = with pkgs; [
      dpkg
      autoPatchelfHook
      makeWrapper
    ];

    buildInputs = with pkgs; [
      stdenv.cc.cc.lib # libstdc++, libgcc_s
      libglvnd # libGL, libGLX, libEGL, libOpenGL
      fontconfig
      freetype
      libgpg-error
      libgcrypt
      zlib
      openssl # libssl/libcrypto, dlopen'd by Qt tls backend
      e2fsprogs # libcom_err
      xorg.libX11
      xorg.libxcb
      xorg.libXau
      xorg.libXdmcp
      libxkbcommon
    ];

    # Only used by the deprecated wl-shell protocol plugin; modern compositors
    # (Hyprland) use xdg-shell, which has its own bundled plugin.
    autoPatchelfIgnoreMissingDeps = ["libQt6WlShellIntegration.so.6"];

    unpackPhase = ''
      runHook preUnpack
      dpkg-deb -x $src .
      runHook postUnpack
    '';

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -r opt $out/opt
      chmod -R u+w $out/opt

      # Qt's openssl TLS backend dlopen's libssl/libcrypto by soname; drop them
      # into the bundled lib dir so the plugin's RUNPATH resolves them.
      ln -s ${pkgs.openssl.out}/lib/libssl.so.3 $out/opt/happ/lib/libssl.so.3
      ln -s ${pkgs.openssl.out}/lib/libcrypto.so.3 $out/opt/happ/lib/libcrypto.so.3

      mkdir -p $out/share
      cp -r usr/share/* $out/share/ 2>/dev/null || true

      # Launcher: exec the real binary so Qt's applicationDirPath resolves to
      # $out/opt/happ/bin and qt.conf finds the bundled plugins/libs.
      makeWrapper $out/opt/happ/bin/Happ $out/bin/happ \
        --unset QT_PLUGIN_PATH \
        --unset QT_QPA_PLATFORM_PLUGIN_PATH \
        --unset QML2_IMPORT_PATH

      ln -s $out/opt/happ/bin/happd $out/bin/happd

      mkdir -p $out/share/applications
      if [ -f usr/share/applications/Happ.desktop ]; then
        substitute usr/share/applications/Happ.desktop $out/share/applications/Happ.desktop \
          --replace /opt/happ/bin/Happ $out/bin/happ
      fi

      runHook postInstall
    '';

    meta = with lib; {
      description = "Happ - cross-platform proxy utility built on Xray core (VLESS/Reality, VMess, Trojan, Shadowsocks)";
      homepage = "https://www.happ.su";
      license = licenses.unfree;
      platforms = ["x86_64-linux"];
      mainProgram = "happ";
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
  networking.firewall.allowedTCPPorts = [19160];
  networking.firewall.allowedUDPPorts = [19160];
  # Lab VM bridges: trust them so libvirt-NATed traffic forwards out.
  # Without this, the NixOS firewall's FORWARD chain drops TCP from these
  # bridges (libvirt's own ACCEPT rules live in a separate hook).
  networking.firewall.trustedInterfaces = [ "virbr-kadm" "virbr-kthw" ];
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
    BROWSER = "vivaldi";
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

  # Vial keyboard configurator - allow access to hidraw devices
  services.udev.extraRules = ''
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
  '';

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

  # # ByeDPI - local SOCKS proxy for DPI bypass
  # systemd.services.byedpi = {
  #   description = "ByeDPI DPI bypass proxy";
  #   after = ["network-online.target"];
  #   wants = ["network-online.target"];
  #   wantedBy = ["multi-user.target"];
  #   serviceConfig = {
  #     Type = "simple";
  #     Restart = "always";
  #     RestartSec = "5";
  #     ExecStart = "${byedpi}/bin/ciadpi --port 1080 --disorder 1 --fake -1 --md5sig --auto=torst --tlsrec 1+s";
  #     DynamicUser = true;
  #   };
  # };

  # Happ process-control daemon. Runs as root so sing-box can create the TUN
  # device and routes (CAP_NET_ADMIN). The Happ GUI (run as your user) connects
  # to it over /tmp/happd.sock (created world-accessible, mode 0666). This
  # replaces Happ's own pkexec-based self-install of the unit, which would
  # otherwise write a /etc unit pointing at a store path that changes on rebuild.
  systemd.services.happd = {
    description = "Happ Process Control Daemon";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    path = with pkgs; [iproute2 iptables nftables];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${happ}/opt/happ/bin/happd";
      Restart = "on-failure";
      RestartSec = "5s";
      TimeoutStopSec = "10s";
      KillMode = "mixed";
      KillSignal = "SIGTERM";
    };
  };
  #
  # # Zapret DPI bypass
  # services.zapret = {
  #   enable = true;
  #   params = [
  #     "--dpi-desync=fake,disorder2"
  #     "--dpi-desync-ttl=6"
  #     "--dpi-desync-fooling=badsum,md5sig"
  #     "--dpi-desync-split-pos=1"
  #     "--dpi-desync-any-protocol"
  #     "--dpi-desync-repeats=6"
  #   ];
  #   whitelist = [
  #     # YouTube
  #     "youtube.com"
  #     "googlevideo.com"
  #     "ytimg.com"
  #     "youtu.be"
  #     "ggpht.com"
  #     "googleapis.com"
  #     "googleusercontent.com"
  #     "gstatic.com"
  #     # Discord
  #     "discord.com"
  #     "discord.gg"
  #     "discordapp.com"
  #     "discordapp.net"
  #     "discord.media"
  #     "discordcdn.com"
  #     # Telegram
  #     "telegram.org"
  #     "t.me"
  #     "telegram.me"
  #     # Other commonly blocked
  #     "facebook.com"
  #     "instagram.com"
  #     "twitter.com"
  #     "x.com"
  #     "twimg.com"
  #   ];
  #   udpSupport = true;
  #   udpPorts = ["50000:65535"];
  # };

  networking.firewall.checkReversePath = "loose";

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

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm; # KVM-accelerated QEMU
      runAsRoot = false;
      swtpm.enable = true; # virtual TPM, useful for modern guests
      ovmf = {
        enable = true;
        packages = [pkgs.OVMFFull.fd]; # UEFI firmware for guests
      };
    };
  };

  programs.virt-manager.enable = true;

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
  users.users.misha.extraGroups = ["wheel" "video" "audio" "input" "docker" "netdev" "firezone-client" "libvirtd" "kvm"];

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
          ${pkgs.bluez}/bin/bluetoothctl connect 58:18:62:38:A8:69
          sleep 1
        done
      ''}";
    };
  };

  # Keep a saddr-based bypass at the top of sing-box's prerouting chain so
  # libvirt VM traffic (10.0.0.0/23) and in-cluster K8s traffic (pod CIDR
  # 10.244.0.0/16, service CIDR 10.96.0.0/12) never gets TPROXY'd through
  # throne-tun. Two problems this avoids:
  #   1. Pod-to-pod via Service VIP: Cilium DNATs to a pod IP (10.244.x.x);
  #      with bridge-nf-call-iptables=1 these frames hit the host's nft IP
  #      hooks. sing-box redirects them and routes via the `direct` outbound,
  #      which runs from the HOST — and the host has no route to 10.244/16
  #      (only K8s nodes do), so the connection silently times out.
  #   2. VM-to-internet: sustained flows die because throne-tun has lower
  #      effective MTU/throughput than the underlying link.
  # The libvirt-hook approach (/etc/libvirt/hooks/network) doesn't suffice
  # because Throne starts in user session AFTER libvirtd brings the networks
  # up, so the sing-box chain doesn't exist when the hook fires. This watcher
  # polls every 5s and re-inserts the rule whenever Throne (re)creates the
  # chain — survives reboots and Throne restarts.
  systemd.services.sing-box-vm-bypass = {
    description = "Re-insert sing-box bypass rule for libvirt VMs + k8s CIDRs";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = 5;
    };
    script = ''
      NFT=${pkgs.nftables}/bin/nft
      while true; do
        if $NFT list chain inet sing-box prerouting >/dev/null 2>&1 \
           && ! $NFT list chain inet sing-box prerouting | grep -q '10.244.0.0/16'; then
          $NFT insert rule inet sing-box prerouting \
            ip saddr '{ 10.0.0.0/23, 10.244.0.0/16, 10.96.0.0/12 }' counter return
        fi
        sleep 5
      done
    '';
  };

  # Make corporate (OpenVPN tun0) destinations bypass Throne at the *kernel*
  # level by populating sing-box's `inet4_local_address_set` nftables set.
  # Without this, packets to RFC1918 corp IPs (e.g. gitlab.timeweb.net at
  # 192.168.4.2) are marked 0x2023 by sing-box's output chain, diverted into
  # throne-tun, and sing-box's userspace "direct" outbound tries to re-emit
  # them from the host — which fails because the host has no route to the
  # private corp subnet without going through tun0. The kernel bypass set
  # is the *only* layer where exclusions reliably short-circuit before any
  # marking happens, letting longest-prefix-match in the main routing table
  # pick OpenVPN's pushed routes.
  #
  # Throne's UI "Direct" rule field only configures sing-box's `route.rules`
  # (userspace, post-tun), NOT the TUN inbound's `inet4_route_exclude_address`
  # (which would bake these into the set on every start). So we maintain the
  # set ourselves with a poll loop, same pattern as sing-box-vm-bypass above.
  #
  # Notes on the CIDR list:
  #   - 10.0.0.0/8 is safe to add wholesale (no overlap with auto-added entries).
  #   - 172.16.0.0/12 is intentionally omitted: it would overlap with the
  #     auto-added 172.17.0.0/16 (docker) and 172.19.0.0/24 (throne-tun),
  #     and `flags interval` rejects overlapping intervals.
  #   - 192.168.0.0/16 is similarly omitted (overlaps with the auto-added
  #     192.168.0.0/24 LAN). We list specific corp /24s instead.
  #   - 5.39.0.0/16 and 31.177.76.0/22 are pinned public corp ranges.
  # `nft add element` with `|| true` makes each addition idempotent and
  # tolerant of overlap rejections, so the loop is safe to run continuously.
  systemd.services.throne-corp-bypass = {
    description = "Re-add corp destination CIDRs to Throne nftables bypass set";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = 5;
    };
    script = ''
      NFT=${pkgs.nftables}/bin/nft
      CIDRS="10.0.0.0/8 \
             5.39.0.0/16 \
             31.177.76.0/22 \
             192.168.1.0/24 \
             192.168.2.0/24 \
             192.168.3.0/24 \
             192.168.4.0/24 \
             192.168.7.0/24 \
             192.168.10.0/24 \
             192.168.16.0/24 \
             192.168.17.0/24 \
             192.168.29.0/24 \
             192.168.96.0/24 \
             192.168.252.0/24"
      while true; do
        if $NFT list set inet sing-box inet4_local_address_set >/dev/null 2>&1; then
          for cidr in $CIDRS; do
            $NFT add element inet sing-box inet4_local_address_set "{ $cidr }" 2>/dev/null || true
          done
        fi
        sleep 5
      done
    '';
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
    happ
    throne
    v2rayn
    xray
    webtorrent_desktop
    qbittorrent
    vial
    codecrafters-cli
    lsof
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
