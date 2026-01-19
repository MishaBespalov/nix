{
  pkgs,
  ...
}: {
  programs.k9s = {
    enable = true;

    # Set default skin and custom ayu theme
    settings = {
      k9s = {
        ui = {
          skin = "ayu";
        };
      };
    };

    skins = {
      ayu = {
        k9s = {
          body = {
            fgColor = "#e6e1cf";
            bgColor = "#0f1419";
            logoColor = "#ffb454";
          };
          prompt = {
            fgColor = "#e6e1cf";
            bgColor = "#131721";
            suggestColor = "#5c6773";
          };
          info = {
            fgColor = "#b3b1ad";
            sectionColor = "#e6e1cf";
          };
          dialog = {
            fgColor = "#e6e1cf";
            bgColor = "#131721";
            buttonFgColor = "#e6e1cf";
            buttonBgColor = "#39bae6";
            buttonFocusFgColor = "#0f1419";
            buttonFocusBgColor = "#ffb454";
            labelFgColor = "#ff3333";
            fieldFgColor = "#e6e1cf";
          };
          frame = {
            border = {
              fgColor = "#5c6773";
              focusColor = "#ffb454";
            };
            menu = {
              fgColor = "#e6e1cf";
              keyColor = "#ffb454";
              numKeyColor = "#ffb454";
            };
            crumbs = {
              fgColor = "#131721";
              bgColor = "#39bae6";
              activeColor = "#ffb454";
            };
            status = {
              newColor = "#c2d94c";
              modifyColor = "#39bae6";
              addColor = "#c2d94c";
              errorColor = "#ff3333";
              highlightColor = "#ffb454";
              killColor = "#ff3333";
              completedColor = "#b3b1ad";
            };
            title = {
              fgColor = "#e6e1cf";
              bgColor = "#131721";
              highlightColor = "#ffb454";
              counterColor = "#b3b1ad";
              filterColor = "#ffb454";
            };
          };
          views = {
            charts = {
              bgColor = "#0f1419";
              dialBgColor = "#131721";
              chartBgColor = "#131721";
              defaultDialColors = ["#ff3333" "#c2d94c" "#ffb454" "#39bae6" "#d4bfff" "#95e6cb"];
              defaultChartColors = ["#ff3333" "#c2d94c" "#ffb454" "#39bae6" "#d4bfff" "#95e6cb"];
            };
            table = {
              fgColor = "#e6e1cf";
              bgColor = "#0f1419";
              cursorFgColor = "#0f1419";
              cursorBgColor = "#ffb454";
              markColor = "#ffb454";
              header = {
                fgColor = "#e6e1cf";
                bgColor = "#131721";
                sorterColor = "#39bae6";
              };
            };
            xray = {
              fgColor = "#e6e1cf";
              bgColor = "#0f1419";
              cursorColor = "#ffb454";
              graphicColor = "#39bae6";
              showIcons = false;
            };
            yaml = {
              keyColor = "#39bae6";
              colonColor = "#b3b1ad";
              valueColor = "#e6e1cf";
            };
            logs = {
              fgColor = "#e6e1cf";
              bgColor = "#0f1419";
              indicator = {
                fgColor = "#b3b1ad";
                bgColor = "#131721";
                toggleOnColor = "#c2d94c";
                toggleOffColor = "#ff3333";
              };
            };
          };
        };
      };
    };
  };
}