{
  config,
  lib,
  pkgs,
  ...
}: let
  secrets = import ./secrets.nix;
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
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.
  networking.networkmanager.dns = "systemd-resolved";
  networking.networkmanager.plugins = with pkgs; [
    networkmanager-openvpn
    networkmanager-openconnect
  ];
  services.resolved.enable = true;

  time.timeZone = "Europe/Moscow";

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

  # KVM / QEMU
  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.qemu.ovmf.enable = true;
  virtualisation.libvirtd.qemu.swtpm.enable = true;
  programs.virt-manager.enable = true;
  networking.firewall.trustedInterfaces = ["virbr0"];

  # Add user to netdev group for TUN access
  users.users.misha.extraGroups = ["wheel" "video" "audio" "input" "docker" "netdev" "firezone-client" "libvirtd"];

  # Sing-box VPN service
  systemd.services.sing-box = {
    description = "Sing-box proxy service";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = "5";
      ExecStart = "${pkgs.sing-box}/bin/sing-box run -c /home/misha/sing-box/main.json";
      User = "root";
      Group = "root";
    };
  };

  programs.hyprland.enable = true;
  programs.fish.enable = true;
  programs.direnv.enable = true;
  security.polkit.enable = true;
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
          ${pkgs.bluez}/bin/bluetoothctl connect ${secrets.bluetoothHeadsetMAC}
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
    qemu
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
