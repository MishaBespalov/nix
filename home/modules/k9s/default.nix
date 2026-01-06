{
  pkgs,
  ...
}: {
  programs.k9s = {
    enable = true;

    # Set default skin and custom gruvbox dark theme
    settings = {
      k9s = {
        ui = {
          skin = "gruvbox_dark";
        };
      };
    };

    skins = {
      gruvbox_dark = {
        k9s = {
          body = {
            fgColor = "#d5c4a1"; # softer gruvbox light4 instead of bright fg1
            bgColor = "#282828"; # softer gruvbox bg0 instead of hard bg0
            logoColor = "#d79921"; # muted yellow instead of bright yellow
          };
          prompt = {
            fgColor = "#ebdbb2"; # softer fg1 instead of brightest fg0
            bgColor = "#3c3836"; # keep bg1 for subtle contrast
            suggestColor = "#7c6f64"; # muted bg4 instead of bright blue
          };
          info = {
            fgColor = "#bdae93"; # softer fg3 instead of purple
            sectionColor = "#d5c4a1"; # softer light4 instead of bright fg0
          };
          dialog = {
            fgColor = "#d5c4a1"; # softer light4 instead of bright fg0
            bgColor = "#3c3836"; # keep bg1
            buttonFgColor = "#504945"; # softer bg2 instead of harsh dark
            buttonBgColor = "#7c6f64"; # muted bg4 instead of bright blue
            buttonFocusFgColor = "#282828"; # softer bg0 instead of harsh dark
            buttonFocusBgColor = "#d79921"; # muted yellow instead of bright
            labelFgColor = "#cc241d"; # softer red instead of bright red
            fieldFgColor = "#d5c4a1"; # softer light4
          };
          frame = {
            border = {
              fgColor = "#504945"; # softer bg2 instead of bg3
              focusColor = "#d79921"; # muted yellow instead of bright
            };
            menu = {
              fgColor = "#d5c4a1"; # softer light4
              keyColor = "#bdae93"; # muted fg3 instead of purple
              numKeyColor = "#bdae93"; # muted fg3
            };
            crumbs = {
              fgColor = "#3c3836"; # softer bg1 instead of harsh dark
              bgColor = "#7c6f64"; # muted bg4 instead of bright blue
              activeColor = "#d79921"; # muted yellow
            };
            status = {
              newColor = "#98971a"; # softer green instead of bright
              modifyColor = "#7c6f64"; # muted bg4 instead of bright blue
              addColor = "#689d6a"; # softer aqua instead of bright
              errorColor = "#cc241d"; # softer red instead of bright
              highlightColor = "#d65d0e"; # softer orange instead of bright
              killColor = "#cc241d"; # softer red
              completedColor = "#928374"; # keep muted gray
            };
            title = {
              fgColor = "#ebdbb2"; # softer fg1 instead of bright fg0
              bgColor = "#3c3836"; # softer bg1 instead of bg0
              highlightColor = "#d79921"; # muted yellow
              counterColor = "#bdae93"; # muted fg3 instead of purple
              filterColor = "#d79921"; # muted yellow
            };
          };
          views = {
            charts = {
              bgColor = "#282828"; # softer bg0 instead of hard
              dialBgColor = "#3c3836"; # keep bg1
              chartBgColor = "#504945"; # softer bg2 for subtle contrast
              defaultDialColors = ["#cc241d" "#98971a" "#d79921" "#458588" "#b16286" "#689d6a"]; # muted palette
              defaultChartColors = ["#cc241d" "#98971a" "#d79921" "#458588" "#b16286" "#689d6a"]; # muted palette
            };
            table = {
              fgColor = "#d5c4a1"; # softer light4
              bgColor = "#282828"; # softer bg0 instead of hard
              cursorFgColor = "#3c3836"; # softer bg1 instead of harsh dark
              cursorBgColor = "#d79921"; # muted yellow
              markColor = "#bdae93"; # muted fg3 instead of purple
              header = {
                fgColor = "#ebdbb2"; # softer fg1
                bgColor = "#504945"; # softer bg2 for subtle contrast
                sorterColor = "#7c6f64"; # muted bg4 instead of bright blue
              };
            };
            xray = {
              fgColor = "#d5c4a1"; # softer light4
              bgColor = "#282828"; # softer bg0
              cursorColor = "#d79921"; # muted yellow
              graphicColor = "#7c6f64"; # muted bg4 instead of bright blue
              showIcons = false;
            };
            yaml = {
              keyColor = "#7c6f64"; # muted bg4 instead of bright blue
              colonColor = "#928374"; # keep muted gray
              valueColor = "#d5c4a1"; # softer light4
            };
            logs = {
              fgColor = "#d5c4a1"; # softer light4
              bgColor = "#282828"; # softer bg0
              indicator = {
                fgColor = "#bdae93"; # muted fg3 instead of purple
                bgColor = "#3c3836"; # keep bg1
                toggleOnColor = "#98971a"; # softer green
                toggleOffColor = "#cc241d"; # softer red
              };
            };
          };
        };
      };
    };
  };
}
