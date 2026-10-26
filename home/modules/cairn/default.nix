{pkgs, ...}: let
  # Native Hearthstone deck tracker. It only tails the logs the game writes
  # inside the Battle.net Proton prefix (see the battlenet command in the
  # desktop module), so it runs outside Wine. Upstream ships no Nix package and
  # its install.sh builds a pip venv, whose PySide6 wheels do not run on NixOS.
  cairn = pkgs.python3Packages.buildPythonApplication {
    pname = "cairn-tracker";
    version = "1.0.4";
    pyproject = true;

    src = pkgs.fetchFromGitHub {
      owner = "Ratpido-dev";
      repo = "cairn";
      rev = "91c48528a7a0cea46cf7d16a40cb408e5f43ce8a";
      hash = "sha256-KW61nC9UbB6DqEF2FwYrm0CVFc/6H6FQiFNg/IYgZpM=";
    };

    build-system = [pkgs.python3Packages.setuptools];
    dependencies = [pkgs.python3Packages.pyside6];

    nativeBuildInputs = [pkgs.qt6.wrapQtAppsHook];
    buildInputs = [pkgs.qt6.qtbase pkgs.qt6.qtdeclarative pkgs.qt6.qtwayland];

    dontWrapQtApps = true;
    preFixup = ''
      makeWrapperArgs+=("''${qtWrapperArgs[@]}")
    '';

    postInstall = ''
      install -Dm644 packaging/cairn.desktop $out/share/applications/cairn.desktop
      install -Dm644 packaging/cairn.svg $out/share/icons/hicolor/scalable/apps/cairn.svg
    '';

    doCheck = false;
  };
in {
  home.packages = [cairn];
}
