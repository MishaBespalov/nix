{
  description = "Python development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, nixpkgs-unstable, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        unstable = nixpkgs-unstable.legacyPackages.${system};
        
        # Python with commonly used packages for development
        pythonEnv = pkgs.python3.withPackages (ps: with ps; [
          pip
          setuptools
          wheel
          virtualenv
          # Common development packages
          pytest
          black
          mypy
          pylint
          isort
          flake8
          requests
          # Add more packages as needed
        ]);
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pythonEnv
            unstable.pyright      # Python Language Server from unstable (latest available)
            pkgs.poetry          # Python dependency management
            pkgs.uv              # Fast Python package manager
            pkgs.nodePackages.pyright  # Alternative LSP
            
            # Additional development tools
            pkgs.git
            pkgs.gh              # GitHub CLI
          ];
          
          # Environment variables
          shellHook = ''
            echo "🐍 Python development environment activated!"
            echo "Python version: $(python --version)"
            echo "Available tools: poetry, pytest, black, mypy, pyright"
            echo ""
            echo "💡 Quick start commands:"
            echo "  poetry init          # Initialize new project"
            echo "  poetry install       # Install dependencies"
            echo "  poetry add <package> # Add dependency"
            echo "  poetry run python    # Run Python in venv"
          '';
        };
      });
}