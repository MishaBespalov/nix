{
  pkgs,
  ...
}: {
  programs.k9s = {
    enable = true;

    # Set default skin and custom gitlab dark theme
    settings = {
      k9s = {
        ui = {
          skin = "gitlab_dark";
        };
        shellPod = {
          image = "busybox:1.35.0";
          namespace = "default";
          limits = {
            cpu = "100m";
            memory = "100Mi";
          };
        };
      };
    };

    skins = {
      gitlab_dark = {
        k9s = {
          body = {
            fgColor = "#ececef"; # gitlab text
            bgColor = "#28262b"; # gitlab dark background
            logoColor = "#d99530"; # gitlab orange
          };
          prompt = {
            fgColor = "#ececef"; # gitlab text
            bgColor = "#333238"; # gitlab gray-900 for subtle contrast
            suggestColor = "#737278"; # gitlab gray-500
          };
          info = {
            fgColor = "#a4a3a8"; # gitlab gray-300
            sectionColor = "#bfbfc3"; # gitlab gray-200
          };
          dialog = {
            fgColor = "#bfbfc3"; # gitlab gray-200
            bgColor = "#333238"; # gitlab gray-900
            buttonFgColor = "#28262b"; # gitlab dark background
            buttonBgColor = "#737278"; # gitlab gray-500
            buttonFocusFgColor = "#28262b"; # gitlab dark background
            buttonFocusBgColor = "#d99530"; # gitlab orange
            labelFgColor = "#f57f6c"; # gitlab red
            fieldFgColor = "#bfbfc3"; # gitlab gray-200
          };
          frame = {
            border = {
              fgColor = "#434248"; # gitlab gray-800
              focusColor = "#d99530"; # gitlab orange
            };
            menu = {
              fgColor = "#bfbfc3"; # gitlab gray-200
              keyColor = "#a4a3a8"; # gitlab gray-300
              numKeyColor = "#a4a3a8"; # gitlab gray-300
            };
            crumbs = {
              fgColor = "#333238"; # gitlab gray-900
              bgColor = "#737278"; # gitlab gray-500
              activeColor = "#d99530"; # gitlab orange
            };
            status = {
              newColor = "#52b87a"; # gitlab green
              modifyColor = "#737278"; # gitlab gray-500
              addColor = "#32c5d2"; # gitlab cyan
              errorColor = "#f57f6c"; # gitlab red
              highlightColor = "#e9be74"; # gitlab bright yellow
              killColor = "#f57f6c"; # gitlab red
              completedColor = "#89888d"; # gitlab gray-400
            };
            title = {
              fgColor = "#ececef"; # gitlab text
              bgColor = "#333238"; # gitlab gray-900
              highlightColor = "#d99530"; # gitlab orange
              counterColor = "#a4a3a8"; # gitlab gray-300
              filterColor = "#d99530"; # gitlab orange
            };
          };
          views = {
            charts = {
              bgColor = "#28262b"; # gitlab dark background
              dialBgColor = "#333238"; # gitlab gray-900
              chartBgColor = "#434248"; # gitlab gray-800
              defaultDialColors = ["#f57f6c" "#52b87a" "#d99530" "#7fb6ed" "#ad95e9" "#32c5d2"]; # gitlab palette
              defaultChartColors = ["#f57f6c" "#52b87a" "#d99530" "#7fb6ed" "#ad95e9" "#32c5d2"]; # gitlab palette
            };
            table = {
              fgColor = "#bfbfc3"; # gitlab gray-200
              bgColor = "#28262b"; # gitlab dark background
              cursorFgColor = "#28262b"; # gitlab dark background
              cursorBgColor = "#d99530"; # gitlab orange
              markColor = "#a4a3a8"; # gitlab gray-300
              header = {
                fgColor = "#ececef"; # gitlab text
                bgColor = "#434248"; # gitlab gray-800 for subtle contrast
                sorterColor = "#7fb6ed"; # gitlab blue
              };
            };
            xray = {
              fgColor = "#bfbfc3"; # gitlab gray-200
              bgColor = "#28262b"; # gitlab dark background
              cursorColor = "#d99530"; # gitlab orange
              graphicColor = "#737278"; # gitlab gray-500
              showIcons = false;
            };
            yaml = {
              keyColor = "#7fb6ed"; # gitlab blue
              colonColor = "#89888d"; # gitlab gray-400
              valueColor = "#bfbfc3"; # gitlab gray-200
            };
            logs = {
              fgColor = "#bfbfc3"; # gitlab gray-200
              bgColor = "#28262b"; # gitlab dark background
              indicator = {
                fgColor = "#a4a3a8"; # gitlab gray-300
                bgColor = "#333238"; # gitlab gray-900
                toggleOnColor = "#52b87a"; # gitlab green
                toggleOffColor = "#f57f6c"; # gitlab red
              };
            };
          };
        };
      };
    };
  };
}
