{pkgs, ...}: {
  # ✅ Hyprland config via Home Manager (declarative hyprland.conf)
  wayland.windowManager.hyprland = let
    smartCopy = pkgs.writeShellScript "smart-copy" ''
      active_window=$(${pkgs.hyprland}/bin/hyprctl activewindow -j | ${pkgs.jq}/bin/jq -r '.class')

      case "$active_window" in
        "com.mitchellh.ghostty"|"claude-code"|"Alacritty"|"kitty"|"org.wezfurlong.wezterm"|"foot"|"Gnome-terminal"|"terminator"|"xterm"|"konsole")
          ${pkgs.hyprland}/bin/hyprctl dispatch sendshortcut "CTRL SHIFT,C,"
          ;;
        *)
          ${pkgs.hyprland}/bin/hyprctl dispatch sendshortcut "CTRL,C,"
          ;;
      esac
    '';

    smartPaste = pkgs.writeShellScript "smart-paste" ''
      active_window=$(${pkgs.hyprland}/bin/hyprctl activewindow -j | ${pkgs.jq}/bin/jq -r '.class')

      case "$active_window" in
        "com.mitchellh.ghostty"|"claude-code"|"Alacritty"|"kitty"|"org.wezfurlong.wezterm"|"foot"|"Gnome-terminal"|"terminator"|"xterm"|"konsole")
          ${pkgs.hyprland}/bin/hyprctl dispatch sendshortcut "CTRL SHIFT,V,"
          ;;
        *)
          ${pkgs.hyprland}/bin/hyprctl dispatch sendshortcut "CTRL,V,"
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
        "DP-3,1920x1080@280,0x0,1"
        "HDMI-A-1,1920x1080@60,1920x0,1"
      ];
      input = {
        kb_layout = "us,ru";
        kb_options = "grp:caps_toggle";
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
        "col.active_border" = "rgba(665c54FF) rgba(7c6f64FF) 45deg";
        "col.inactive_border" = "rgba(3c383640)";
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
        pseudotile = "yes";
        default_split_ratio = 1.2;
        preserve_split = "yes";
        smart_split = false;
        force_split = 2;
      };
      misc = {
        focus_on_activate = true;
        vfr = true;
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
      };

      cursor = {
        no_hardware_cursors = false;
        hide_on_key_press = true;
        hide_on_touch = true;
      };

      # Auto-start applications in specific workspaces
      exec-once = [
        # Start waybar
        "waybar"

        "[workspace 1 silent] throne"
        "[workspace 2 silent] spotify"
        "[workspace 3 silent] telegram-desktop"
        "[workspace 4 silent] zen"
        "[workspace 5 silent] ghostty"
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
