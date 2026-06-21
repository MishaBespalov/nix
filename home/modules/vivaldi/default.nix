{
  config,
  pkgs,
  lib,
  ...
}: let
  # ---------------------------------------------------------------------------
  # Vivaldi config, the Nix way.
  #
  # Two tiers, because Vivaldi (Chromium) OWNS ~/.config/vivaldi/Default/Preferences
  # and rewrites it at runtime — so it can't be a read-only symlink:
  #
  #   1. Fully declarative  -> the package + the CSS UI mod (plain files/derivations)
  #   2. Reconciled-on-switch -> keybinds & prefs merged into the live Preferences
  #      by an activation script (only safe way to touch a file the app manages).
  # ---------------------------------------------------------------------------

  cssModsDir = "${config.xdg.configHome}/vivaldi-ui-mods";

  # Keyboard shortcut overrides: command -> list of shortcuts.
  # Captured verbatim from the working profile.
  actionsOverride = {
    COMMAND_NEW_TAB = ["ctrl+t"];
    COMMAND_NEW_WINDOW = ["ctrl+alt+n"];
    COMMAND_CLOSE_TAB = ["ctrl+d"];
    COMMAND_SHOW_QUICK_COMMANDS = ["ctrl+n" "ctrl+e" "f2"]; # Zen-style finder
    COMMAND_TAB_SWITCH_1 = ["alt+1" "ctrl+1"];
    COMMAND_TAB_SWITCH_2 = ["alt+2" "ctrl+2"];
    COMMAND_TAB_SWITCH_3 = ["alt+3" "ctrl+3"];
    COMMAND_TAB_SWITCH_4 = ["alt+4" "ctrl+4"];
    COMMAND_TAB_SWITCH_5 = ["alt+5" "ctrl+5"];
    COMMAND_TAB_SWITCH_6 = ["alt+6" "ctrl+6"];
    COMMAND_TAB_SWITCH_7 = ["alt+7" "ctrl+7"];
    COMMAND_TAB_SWITCH_8 = ["alt+8" "ctrl+8"];
    COMMAND_TAB_SWITCH_LAST = ["alt+9" "ctrl+9"];
    COMMAND_SHOW_DOWNLOADS_PANEL = ["ctrl+shift+y"];
    COMMAND_FOCUS_SEARCHFIELD = ["ctrl+k" "ctrl+j"];
    COMMAND_NEW_PRIVATE_WINDOW = ["ctrl+shift+p"];
    COMMAND_SHOW_EXTENSIONS = ["ctrl+shift+a"];
    COMMAND_SHOW_TAB_BUTTON_POPOUT = [];
    COMMAND_TAB_STACK_TILE_VERTICAL = ["ctrl+alt+v"];
    COMMAND_TAB_STACK_TILE_HORIZONTAL = ["ctrl+alt+h"];
    COMMAND_TAB_STACK_TILE_GRID = ["ctrl+alt+g"];
    COMMAND_DISBAND_TILE_GROUP = ["ctrl+alt+u"];
    COMMAND_TOGGLE_PANEL = ["f4" "ctrl+alt+z"];
    COMMAND_PAGE_BACK = ["alt+left" "ctrl+left" "backspace" "z" "ctrl+["];
    COMMAND_PAGE_FORWARD = ["alt+right" "ctrl+right" "x" "ctrl+]"];
  };

  # Non-keyboard prefs (a partial `vivaldi.*` subtree, recursively merged in).
  prefsOverride = {
    appearance.css_ui_mods_directory = cssModsDir;
    quick_commands = {
      open_url_in_new_tab = true; # finder results open in a new tab
      nickname_match_in_new_tab = true;
    };
    tabs.cycle_by_recent_order = false; # Ctrl+Tab cycles in strip order, not MRU
  };

  # GitLab Dark theme, palette lifted from ./shell/ghostty-gitlab-tabs.css,
  # with a custom light-blue accent (#7fb6ed) on the active tab + highlights.
  # The toolbar is darkened via custom.css.
  gitlabThemeId = "5e7b1f3a-9c4d-4b2e-8a6f-1d2c3b4a5e6f";
  gitlabTheme = {
    accentFromPage = false;
    accentOnWindow = false; # subtle: accent only on active tab, not whole window
    accentSaturationLimit = 1;
    alpha = 1;
    backgroundImage = "";
    backgroundPosition = "stretch";
    blur = 0;
    colorAccentBg = "#7fb6ed"; # accent (light blue)
    colorBg = "#28262b";
    colorFg = "#ececef";
    colorHighlightBg = "#7fb6ed";
    colorWindowBg = "#1f1e24";
    contrast = 0;
    dimBlurred = false;
    engineVersion = 1;
    id = gitlabThemeId;
    name = "GitLab Dark";
    preferSystemAccent = false;
    radius = 14;
    simpleScrollbar = true;
    transparencyTabBar = false;
    transparencyTabs = false;
    url = "";
    version = 1;
  };

  actionsJson = pkgs.writeText "vivaldi-actions.json" (builtins.toJSON actionsOverride);
  prefsJson = pkgs.writeText "vivaldi-prefs.json" (builtins.toJSON prefsOverride);
  themeJson = pkgs.writeText "vivaldi-gitlab-theme.json" (builtins.toJSON gitlabTheme);
in {
  # ---- Tier 1: fully declarative ------------------------------------------

  home.packages = [
    # To scale the whole UI crisply, swap the next line for:
    #   (pkgs.vivaldi.override { commandLineArgs = "--force-device-scale-factor=1.2"; })
    pkgs.vivaldi
    pkgs.vivaldi-ffmpeg-codecs
  ];

  # The CSS UI mod (read-only is fine — Vivaldi only reads this folder).
  xdg.configFile."vivaldi-ui-mods/custom.css".text = ''
    /* Show the real favicon on audio tabs instead of Vivaldi's speaker overlay.
       Vivaldi collapses the favicon with `transform: scale(0)`; we reverse it.
       Their rule has no !important, so this wins. */
    #tabs-container .tab.audio-on .favicon,
    #tabs-container .tab.audio-muted .favicon,
    #tabs-container .tab.tab-captured .favicon {
      transform: scale(1) !important;
    }

    /* Hide Vivaldi's per-tab audio/volume icon entirely. */
    #tabs-container .tab-audio {
      display: none !important;
    }

    /* GitLab Dark: keep the accent only on the active tab; make the
       toolbar/header dark (#1f1e24) instead of the accent color. */
    #browser #header,
    #browser .toolbar-mainbar,
    #browser #footer {
      background-color: #1f1e24 !important;
      background-image: none !important;
    }

    /* Relight toolbar button icons (reload/back/forward) — Vivaldi auto-darkens
       them to contrast the light accent, which is invisible on the dark toolbar.
       Scoped to .toolbar-mainbar so the active tab's accent text stays dark. */
    #browser .toolbar-mainbar .button-toolbar > button,
    #browser .toolbar-mainbar .button-toolbar > button .button-icon,
    #browser .toolbar-mainbar .button-toolbar > button svg {
      color: #ececef !important;
      fill: #ececef !important;
    }

    /* Optional: darker left tab bar (uncomment to enable)
    #tabs-tabbar-container { background-color: #14161a !important; } */
  '';

  # ---- Tier 2: reconcile keybinds + prefs into Vivaldi's own Preferences ---

  home.activation.vivaldiReconcile = lib.hm.dag.entryAfter ["writeBoundary"] ''
    pref="${config.xdg.configHome}/vivaldi/Default/Preferences"
    if ${pkgs.procps}/bin/pgrep -f '[v]ivaldi-bin' >/dev/null 2>&1; then
      echo "vivaldi: running — skipped Preferences reconcile (close it, re-run switch)"
    elif [ -f "$pref" ]; then
      tmp="$(${pkgs.coreutils}/bin/mktemp)"
      if ${pkgs.jq}/bin/jq \
           --slurpfile acts ${actionsJson} \
           --slurpfile prefs ${prefsJson} \
           --slurpfile theme ${themeJson} \
           --arg tid "${gitlabThemeId}" \
           'reduce ($acts[0] | to_entries[]) as $e
              (.; .vivaldi.actions[0][$e.key].shortcuts = $e.value)
            | .vivaldi = (.vivaldi * $prefs[0])
            | .vivaldi.themes.user =
                (((.vivaldi.themes.user // []) | map(select(.id != $tid))) + [$theme[0]])
            | .vivaldi.theme.schedule.o_s.dark = $tid
            | .vivaldi.theme.schedule.o_s.light = $tid' \
           "$pref" > "$tmp"; then
        ${pkgs.coreutils}/bin/mv "$tmp" "$pref"
        echo "vivaldi: reconciled keybinds + prefs into Preferences"
      else
        echo "vivaldi: jq merge failed — Preferences left untouched"
        ${pkgs.coreutils}/bin/rm -f "$tmp"
      fi
    else
      echo "vivaldi: no Preferences yet — launch Vivaldi once, then re-run switch"
    fi
  '';
}
