{
  pkgs,
  inputs,
  ...
}: {
  services.hyprsunset = {
    enable = true; # start as a user service on login

    transitions = {
      # Apply warm profile every night at 22:00
      night = {
        calendar = "*-*-* 21:30:00";
        requests = [
          ["temperature" "2500"] # lower = warmer
          # [ "gamma" "85" ]         # optional: 85% perceived brightness
        ];
      };

      # Reset to normal every morning at 06:00
      day = {
        calendar = "*-*-* 06:00:00";
        requests = [
          ["identity"] # disables the tint
          # [ "gamma" "100" ]        # optional: reset gamma to 100%
        ];
      };
    };
  };

  # Minimal mako: simple toast notifications with ayu theme
  services.mako = {
    enable = true;
    settings = {
      anchor = "top-right";
      background-color = "#0f1419";
      text-color = "#e6e1cf";
      border-color = "#ffb454";
      border-radius = 8;
      border-size = 1;
      default-timeout = 5000;
      font = "JetBrains Mono 12";
      height = 100;
      width = 350;
      padding = "10";
      margin = "10";
      layer = "overlay";

      "urgency=low" = {
        default-timeout = 3000;
      };

      "urgency=high" = {
        default-timeout = 10000;
      };

      "app-name=Spotify" = {
        invisible = 1;
      };
    };
  };

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true; # Enable if using XWayland
    package = pkgs.bibata-cursors; # Example package
    name = "Bibata-Modern-Classic"; # Cursor theme name
    size = 16;
  };

  services.hyprpaper = {
    enable = true;

    settings = {
      ipc = "on"; # or: true

      splash = false;
      splash_offset = 2.0;

      preload = [
        "/home/misha/wallpapers/main.png"
      ];

      wallpaper = [
        "DP-3,contain:/home/misha/wallpapers/main.png"
      ];
    };
  };

  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "bottom";
        height = 28;
        margin-bottom = 6;
        margin-left = 8;
        margin-right = 8;
        spacing = 0;
        mode = "dock";
        exclusive = true;

        modules-left = [];
        modules-center = ["clock"];
        modules-right = ["tray"];

        tray = {
          icon-size = 18;
          spacing = 10;
        };

        clock = {
          interval = 1;
          format = "{:%A • %H:%M • %d/%m}";
          tooltip-format = "<tt><big>{calendar}</big></tt>";
          calendar = {
            mode = "year";
            mode-mon-col = 3;
            week-start = 1;
            on-scroll = 1;
            format = {
              months = "<span color='#ffb454'><b>{}</b></span>";
              days = "<span color='#e6e1cf'><b>{}</b></span>";
              weekdays = "<span color='#e6b450'><b>{}</b></span>";
              today = "<span color='#ff3333'><b><u>{}</u></b></span>";
            };
          };
          actions = {
            on-click-right = "mode";
            on-click-forward = "tz_up";
            on-click-backward = "tz_down";
            on-scroll-up = "shift_up";
            on-scroll-down = "shift_down";
          };
        };
      };
    };

    style = ''
      /* Ayu Dark theme for Waybar */
      * {
        border: none;
        border-radius: 0;
        font-family: "JetBrains Mono", monospace;
        font-size: 13px;
        min-height: 0;
      }

      window#waybar {
        background-color: transparent;
        border-radius: 12px;
        color: #e6e1cf;
      }

      #clock {
        background-color: #0f1419;
        color: #e6e1cf;
        padding: 6px 16px;
        border-radius: 10px;
        border: 1px solid #5c6773;
        font-weight: bold;
        font-size: 14px;
        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
      }

      #clock:hover {
        background-color: #131721;
        border-color: #707a8c;
      }

      #tray {
        background-color: #0f1419;
        color: #e6e1cf;
        padding: 6px 16px;
        border-radius: 10px;
        border: 1px solid #5c6773;
        margin-left: 8px;
        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
      }

      #tray > .passive {
        -gtk-icon-effect: dim;
      }

      #tray > .needs-attention {
        -gtk-icon-effect: highlight;
        background-color: #ff3333;
      }

      tooltip {
        background-color: #0f1419;
        border: 1px solid #5c6773;
        border-radius: 8px;
        color: #e6e1cf;
      }

      tooltip label {
        color: #e6e1cf;
      }
    '';
  };

  programs.wofi = {
    enable = true;

    settings = {
      show = "drun";
      prompt = "run:";
      allow_markup = true;
      width = 720;
      height = 360;
      lines = 10;
    };

    # Ayu theme (warm dark colors)
    style = ''
      /* ----- Ayu palette ----- */
      @define-color bg        #0f1419;  /* ayu dark background */
      @define-color bg-alt    #131721;  /* ayu dark background alt */
      @define-color surface   #1f2430;  /* ayu mirage bg (slightly lighter) */
      @define-color text      #e6e1cf;  /* ayu fg */
      @define-color subtext   #b3b1ad;  /* ayu comment/fg idle */
      @define-color accent    #ffb454;  /* ayu orange/yellow */
      @define-color accent2   #39bae6;  /* ayu blue */

      /* ----- base widgets ----- */
      * { font-family: JetBrainsMono Nerd Font, monospace; font-size: 14px; }
      window {
        background: @bg;
        border-radius: 10px;
        border: 1px solid alpha(@accent, 0.25);
      }
      #outer-box { padding: 12px; }
      #input {
        margin-bottom: 10px;
        padding: 8px 10px;
        background: @surface;
        color: @text;
        border-radius: 8px;
        border: 1px solid alpha(@accent, 0.20);
      }
      #scroll {
        background: @bg-alt;
        border-radius: 8px;
        padding: 6px;
      }
      #list { background: transparent; }

      /* ----- rows ----- */
      #entry {
        padding: 6px 8px;
        border-radius: 6px;
        color: @text;
      }
      #entry:hover   { background: alpha(@accent2, 0.12); }
      #entry:selected{
        background: alpha(@accent, 0.20);
        outline: 1px solid alpha(@accent, 0.35);
      }
      #text, #text:selected { color: @text; }

      /* optional: hide scrollbar */
      scrollbar { background: transparent; }
    '';
  };

  services.hypridle.enable = true;

  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        no_fade_in = true;
        no_fade_out = true;
        hide_cursor = false;
        grace = 0;
        disable_loading_bar = true;
      };

      background = [
        {
          monitor = "";
          path = "/home/misha/wallpapers/main.png";
          blur_passes = 2;
          contrast = 1;
          brightness = 0.5;
          vibrancy = 0.2;
          vibrancy_darkness = 0.2;
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "250, 60";
          outline_thickness = 2;
          dots_size = 0.2;
          dots_spacing = 0.35;
          dots_center = true;
          outer_color = "rgba(0, 0, 0, 0)";
          inner_color = "rgba(15, 20, 25, 0.8)"; # ayu dark background with transparency
          font_color = "rgb(230, 225, 207)"; # ayu light foreground
          fade_on_empty = false;
          rounding = -1;
          check_color = "rgb(255, 180, 84)"; # ayu bright yellow/orange
          placeholder_text = "Input Password...";
          hide_input = false;
          position = "0, -200";
          halign = "center";
          valign = "center";
        }
      ];

      label = [
        {
          monitor = "";
          text = "cmd[update:1000] echo \"$(date +\"%A, %B %d\")\"";
          color = "rgba(230, 225, 207, 0.75)"; # ayu light foreground with transparency
          font_size = 22;
          font_family = "JetBrains Mono";
          position = "0, 300";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = "cmd[update:1000] echo \"$(date +\"%-I:%M\")\"";
          color = "rgba(230, 225, 207, 0.75)"; # ayu light foreground with transparency
          font_size = 95;
          font_family = "JetBrains Mono Nerd Font";
          position = "0, 200";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };

  # Set Zen Browser as default browser and VLC as default video player
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "zen-twilight.desktop";
      "x-scheme-handler/http" = "zen-twilight.desktop";
      "x-scheme-handler/https" = "zen-twilight.desktop";
      "x-scheme-handler/about" = "zen-twilight.desktop";
      "x-scheme-handler/unknown" = "zen-twilight.desktop";
      "application/pdf" = "zen-twilight.desktop";

      # Video files - VLC as default
      "video/mp4" = "vlc.desktop";
      "video/mpeg" = "vlc.desktop";
      "video/quicktime" = "vlc.desktop";
      "video/x-msvideo" = "vlc.desktop";
      "video/x-ms-wmv" = "vlc.desktop";
      "video/x-flv" = "vlc.desktop";
      "video/webm" = "vlc.desktop";
      "video/3gpp" = "vlc.desktop";
      "video/mp2t" = "vlc.desktop";
      "video/x-matroska" = "vlc.desktop";
    };
  };
}

