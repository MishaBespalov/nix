{pkgs, ...}: {
  # ✅ Hyprland config via Home Manager (declarative hyprland.conf)
  wayland.windowManager.hyprland = let
    # The third `sendshortcut` field is the target window. Hyprland 0.56 splits
    # the argument into exactly 3 fields and rejects anything else, so the old
    # trailing-comma form ("CTRL,C,") now fails with "invalid args" and the
    # keybind silently does nothing. `active` names the focused window.
    smartCopy = pkgs.writeShellScript "smart-copy" ''
      active_window=$(${pkgs.hyprland}/bin/hyprctl activewindow -j | ${pkgs.jq}/bin/jq -r '.class')

      case "$active_window" in
        "com.mitchellh.ghostty"|"claude-code"|"Alacritty"|"kitty"|"org.wezfurlong.wezterm"|"foot"|"Gnome-terminal"|"terminator"|"xterm"|"konsole")
          ${pkgs.hyprland}/bin/hyprctl dispatch sendshortcut "CTRL SHIFT,C,active"
          ;;
        *)
          ${pkgs.hyprland}/bin/hyprctl dispatch sendshortcut "CTRL,C,active"
          ;;
      esac
    '';

    smartPaste = pkgs.writeShellScript "smart-paste" ''
      active_window=$(${pkgs.hyprland}/bin/hyprctl activewindow -j | ${pkgs.jq}/bin/jq -r '.class')

      case "$active_window" in
        "com.mitchellh.ghostty"|"claude-code"|"Alacritty"|"kitty"|"org.wezfurlong.wezterm"|"foot"|"Gnome-terminal"|"terminator"|"xterm"|"konsole")
          ${pkgs.hyprland}/bin/hyprctl dispatch sendshortcut "CTRL SHIFT,V,active"
          ;;
        *)
          ${pkgs.hyprland}/bin/hyprctl dispatch sendshortcut "CTRL,V,active"
          ;;
      esac
    '';
  in {
    enable = true;
    # Use the system's Hyprland from the NixOS module to avoid version mixups.
    package = pkgs.hyprland;
    portalPackage = null;

    settings = {
      "$mainMod" = "SUPER";
      "$terminal" = "ghostty";
      "$browser" = "zen";
      "$telegram" = "telegram-desktop";
      "$menu" = "wofi --show drun";
      monitor = [
        # Match by EDID description: the connector name changes depending on
        # whether the panel hangs off the iGPU or the OCuLink eGPU.
        "desc:MKG MKF25F240,1920x1080@280,0x0,1"
        ",preferred,auto,1"
      ];
      input = {
        kb_layout = "us,ru";
        kb_options = "grp:caps_toggle,grp:shift_caps_toggle";
        kb_variant = "";
        kb_model = "pc105";

        repeat_delay = 210;
        repeat_rate = 50;

        accel_profile = "adaptive";
        sensitivity = -1;

        follow_mouse = 1;

        touchpad = {
          natural_scroll = false;
          "tap-and-drag" = false; # hyphen keys must be quoted in HM
          "drag_lock" = false;
        };
      };

      general = {
        gaps_in = 6;
        gaps_out = 12;
        border_size = 1;
        "col.active_border" = "rgba(535158FF) rgba(737278FF) 45deg";
        "col.inactive_border" = "rgba(33323840)";
      };
      decoration = {
        rounding = 8;
        blur = {
          enabled = true;
          size = 5;
          passes = 3;
        };
      };
      animations = {enabled = true;};

      bezier = ["fast, 0.05, 0.9, 0.1, 1.05"];

      animation = [
        # windows open/close + moves
        "windows,      1, 3, fast, popin 80%" # reduced from 6 to 3
        "windowsMove,  1, 2, fast" # reduced from 4 to 2

        # fades & borders
        "fade,         1, 3, default" # reduced from 5 to 3
        "border,       1, 2, default" # reduced from 4 to 2

        # workspace switching
        "workspaces,   1, 4, default, slide" # reduced from 6 to 3
      ];

      dwindle = {
        # No `pseudotile` here: Hyprland dropped the global default in 0.5x.
        # Pseudotiling itself is alive, as the per-window `pseudo` dispatcher.
        default_split_ratio = 1.2;
        preserve_split = "yes";
        smart_split = false;
        force_split = 2;
      };
      misc = {
        focus_on_activate = true;
        # `vfr` moved to `debug:vfr` and now defaults to on, so it is gone from
        # here rather than renamed; upstream says not to touch it outside of
        # debugging. Behaviour is unchanged.
        vrr = 2; # FreeSync only while a fullscreen app (game) is focused

        disable_hyprland_logo = true;
        disable_splash_rendering = true;
      };

      cursor = {
        no_hardware_cursors = false;
        hide_on_key_press = true;
        hide_on_touch = true;
      };

      # Steam games run as floating XWayland windows sized over the screen;
      # without real fullscreen they lose keyboard focus while the game keeps
      # the pointer grab (mouse works, keys dead). Force proper fullscreen.
      #
      # Deliberately no `immediate` (tearing) rule, and no general:allow_tearing
      # to back it. Tearing made Hyprland 0.49 ask for async page flips that
      # amdgpu rejected with EINVAL on every frame; the page-flip event then
      # never arrived and aquamarine tore down an already-freed event source,
      # segfaulting the compositor mid-match. Killed the session three times in
      # Overwatch (Aug 25, 27, 31). On a 280 Hz panel with FreeSync the latency
      # tearing would have bought back is not worth it.
      # 0.56 rule grammar: comma-separated `name value` fields, matchers
      # prefixed with `match:`, effects bare. The old `fullscreen, class:...`
      # form parses as an effect with no value and is rejected outright.
      windowrule = [
        "fullscreen true, match:class ^(steam_app_\\d+)$"
      ];

      # Auto-start applications in specific workspaces
      exec-once = [
        # Start waybar
        "waybar"

        "[workspace 1 silent] happ"
        # "[workspace 2 silent] spotify"
        "[workspace 2 silent] telegram-desktop"
        "[workspace 3 silent] zen"
        "[workspace 4 silent] ghostty"
      ];

      bind = [
        "CTRL ALT, 9, exec, ${smartPaste}"
        "CTRL ALT, 8, exec, ${smartCopy}"
        "$mainMod, 4, exec, ghostty"
        "$mainMod, 5, killactive,"
        "$mainMod, 0, exec, wofi --show drun"
        "$mainMod, 2, exec, $telegram"
        "$mainMod, 3, exec, $browser"
        "$mainMod, 8, exec, hyprlock"
        "$mainMod, W, exec, pkill -SIGUSR1 waybar"
        "$mainMod, left,  workspace, r-1"
        "$mainMod, right, workspace, r+1"
        "$mainMod CTRL, left, movefocus, l"
        "$mainMod CTRL, right, movefocus, r"
        "$mainMod CTRL, up, movefocus, u"
        "$mainMod CTRL, down, movefocus, d"
        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"
        "$mainMod SHIFT, 8, movetoworkspace, 8"
        "$mainMod SHIFT, 9, movetoworkspace, 9"
        "$mainMod SHIFT, 0, movetoworkspace, 10"
        "$mainMod, 9, exec, hyprshot -m region"
      ];
      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];
    };
  };
}
