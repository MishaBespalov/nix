{
  config,
  pkgs,
  inputs,
  ...
}: {
  programs.zoxide.enable = true;
  programs.fzf.enable = true;
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.bat = {
    enable = true;
    config = {
      theme = "gruvbox-dark";
      style = "numbers,changes,header";
    };
  };

  programs.fish = {
    enable = true;

    functions.fish_greeting.body = ''
      # no output -> no greeting
    '';

    # Runs for interactive shells (good for env tweaks)
    interactiveShellInit = ''
           if test "$TERM_PROGRAM" = "ghostty"
      set -x TERM xterm-256color
           end

    '';

    # Aliases from your old config
    shellAliases = {
      vim = "nvim";
      cat = "bat -P";
      ls = "eza";
      curl = "curlie";
    };

    # Your `r` function (ported 1:1)
    functions.r.body = ''
           set tmp (mktemp -t "yazi-cwd.XXXXXX")
           yazi $argv --cwd-file="$tmp"
           if set cwd (command cat -- "$tmp"); and test -n "$cwd"; and test "$cwd" != "$PWD"
      builtin cd -- "$cwd"
           end
           rm -f -- "$tmp"
    '';

    # cd function that tries zoxide first, falls back to builtin cd
    functions.cd.body = ''
      # Try zoxide first
      if z $argv 2>/dev/null
        # If zoxide succeeds, we're done
        return 0
      else
        # If zoxide fails, fall back to builtin cd
        builtin cd $argv
      end
    '';

    # Automated Zig project creation with full setup
    functions.zig-new.body = ''
      set project_name $argv[1]
      if test -z "$project_name"
        echo "Usage: zig-new <project-name>"
        return 1
      end

      echo "🚀 Creating Zig project: $project_name"

      # Create the project from template
      if not nix flake new -t /home/misha/nixos-dotfiles#zig "$project_name"
        echo "❌ Failed to create project from template"
        return 1
      end

      # Navigate to project directory
      cd "$project_name"

      # Initialize Zig project
      echo "⚡ Initializing Zig executable project..."
      zig init-exe

      # Initialize git repository
      echo "📦 Initializing git repository..."
      git init -b main
      git add .
      git commit -m "Initial commit: Zig project setup"

      # Automatically allow direnv
      echo "🔒 Allowing direnv..."
      direnv allow

      echo "✅ Project '$project_name' ready! Environment activated."
      echo "💡 Run 'zig build' to build or 'zig build run' to run"
      echo "🔗 Git repository initialized with initial commit"

      # Additional zig init for interactive configuration
      zig init
    '';

    # Initialize existing directory with Zig Nix environment
    functions.zig-init.body = ''
      echo "⚡ Initializing Zig Nix environment in current directory..."

      # Check if we're in a directory
      if test (pwd) = "/"
        echo "❌ Cannot initialize in root directory"
        return 1
      end

      # Check if flake.nix already exists
      if test -f flake.nix
        echo "⚠️  flake.nix already exists. Overwrite? (y/N)"
        read -l response
        if test "$response" != "y" -a "$response" != "Y"
          echo "❌ Aborted"
          return 1
        end
      end

      echo "📁 Current directory: $(basename (pwd))"

      # Copy flake.nix from template
      echo "📝 Creating flake.nix from template..."
      if not cp /home/misha/nixos-dotfiles/templates/zig/flake.nix ./flake.nix
        echo "❌ Failed to copy flake.nix template"
        return 1
      end

      # Create .envrc for direnv
      echo "🔧 Setting up direnv..."
      echo "use flake" > .envrc

      # Automatically allow direnv
      echo "🔒 Allowing direnv..."
      direnv allow

      # Add to git if it's a git repository
      if test -d .git
        echo "📦 Adding flake files to git..."
        git add flake.nix .envrc
        echo "💡 Files added to git staging area. Run 'git commit' when ready."
      end

      echo "✅ Zig Nix environment initialized!"
      echo "💡 Run 'nix develop' or wait for direnv to activate the environment"
      echo "🔧 Available tools: zig, zls (Zig Language Server)"
    '';

    # Automated Rust project creation with full setup
    functions.rust-new.body = ''
      set project_name $argv[1]
      if test -z "$project_name"
        echo "Usage: rust-new <project-name>"
        return 1
      end

      echo "🦀 Creating Rust project: $project_name"

      # Create the project from template
      if not nix flake new -t /home/misha/nixos-dotfiles#rust "$project_name"
        echo "❌ Failed to create project from template"
        return 1
      end

      # Navigate to project directory
      cd "$project_name"

      # Initialize Rust project
      echo "⚡ Initializing Rust binary project..."
      cargo init --name "$project_name"

      # Initialize git repository
      echo "📦 Initializing git repository..."
      git init -b main -b main
      git add .
      git commit -m "Initial commit: Rust project setup"

      # Automatically allow direnv
      echo "🔒 Allowing direnv..."
      direnv allow

      echo "✅ Project '$project_name' ready! Environment activated."
      echo "💡 Run 'cargo build' to build or 'cargo run' to run"
      echo "🔗 Git repository initialized with initial commit"
    '';

    # Automated Rust workspace creation with full setup
    functions.cargo-workspace.body = ''
      set workspace_name $argv[1]
      set crates $argv[2..-1]

      if test -z "$workspace_name"
        echo "Usage: cargo-workspace <workspace-name> [crate1] [crate2] ..."
        echo "Example: cargo-workspace myproject common agent api"
        return 1
      end

      echo "🦀 Creating Rust workspace: $workspace_name"

      # Create the workspace from template
      if not nix flake new -t /home/misha/nixos-dotfiles#rust "$workspace_name"
        echo "❌ Failed to create project from template"
        return 1
      end

      # Navigate to workspace directory
      cd "$workspace_name"

      # Create workspace Cargo.toml
      echo "📦 Creating workspace Cargo.toml..."
      echo '[workspace]' > Cargo.toml
      echo 'resolver = "2"' >> Cargo.toml
      echo 'members = ["crates/*"]' >> Cargo.toml

      # Create .envrc for direnv
      echo "🔧 Setting up direnv..."
      echo "use flake" > .envrc

      # Create crates directory
      mkdir -p crates

      # Create each crate
      if test (count $crates) -gt 0
        for crate in $crates
          echo "📦 Creating crate: $crate"
          cargo new "crates/$crate" --lib
        end
      end

      # Initialize git repository
      echo "📦 Initializing git repository..."
      git init -b main
      git add .
      git commit -m "Initial commit: Rust workspace setup"

      # Automatically allow direnv
      echo "🔒 Allowing direnv..."
      direnv allow

      echo "✅ Workspace '$workspace_name' ready! Environment activated."
      if test (count $crates) -gt 0
        echo "📦 Created crates: $crates"
      end
      echo "💡 Add more crates with: cargo new crates/<name> --lib"
      echo "🔗 Git repository initialized with initial commit"
    '';

    # Automated Go project creation with full setup
    functions.go-new.body = ''
            set project_name $argv[1]
            if test -z "$project_name"
              echo "Usage: go-new <project-name>"
              return 1
            end

            echo "🐹 Creating Go project: $project_name"

            # Create the project from template
            if not nix flake new -t /home/misha/nixos-dotfiles#go "$project_name"
              echo "❌ Failed to create project from template"
              return 1
            end

            # Navigate to project directory
            cd "$project_name"

            # Initialize Go module
            echo "⚡ Initializing Go module..."
            go mod init "$project_name"

            # Create main.go file
            echo "📝 Creating main.go..."
            echo 'package main

      import "fmt"

      func main() {
      	fmt.Println("Hello, World!")
      }' > main.go

            # Create .envrc for direnv
            echo "🔧 Setting up direnv..."
            echo "use flake" > .envrc

            # Initialize git repository
            echo "📦 Initializing git repository..."
            git init
            git add .
            git commit -m "Initial commit: Go project setup"

            # Automatically allow direnv
            echo "🔒 Allowing direnv..."
            direnv allow

            echo "✅ Project '$project_name' ready! Environment activated."
            echo "💡 Run 'go build' to build or 'go run main.go' to run"
            echo "🔗 Git repository initialized with initial commit"
    '';

    # Automated Python project creation with full setup
    functions.python-new.body = ''
      set project_name $argv[1]
      if test -z "$project_name"
        echo "Usage: python-new <project-name>"
        return 1
      end

      echo "🐍 Creating Python project: $project_name"

      # Create the project from template
      if not nix flake new -t /home/misha/nixos-dotfiles#python "$project_name"
        echo "❌ Failed to create project from template"
        return 1
      end

      # Navigate to project directory
      cd "$project_name"

      # Initialize Poetry project (preferred for Python dependency management)
      echo "📦 Initializing Poetry project..."
      poetry init --name "$project_name" --dependency "pytest^7.0.0" --no-interaction

      # Create basic project structure
      echo "📁 Creating project structure..."
      mkdir -p src/"$project_name" tests docs

      # Create main module
      echo 'package main

      import "fmt"

      func main() {
      	fmt.Println("Hello, World!")
      }' > src/"$project_name"/__init__.py
      echo '    """Main entry point for '"$project_name"'."""' >> src/"$project_name"/__init__.py
      echo '    print("Hello from '"$project_name"'!")' >> src/"$project_name"/__init__.py
      echo "" >> src/"$project_name"/__init__.py
      echo 'if __name__ == "__main__":' >> src/"$project_name"/__init__.py
      echo "    main()" >> src/"$project_name"/__init__.py

      # Create a basic test
      echo 'import pytest' > tests/test_main.py
      echo "from src.$project_name import main" >> tests/test_main.py
      echo "" >> tests/test_main.py
      echo "def test_main():" >> tests/test_main.py
      echo '    """Test the main function."""' >> tests/test_main.py
      echo "    # This test just ensures main() can be called without errors" >> tests/test_main.py
      echo "    main()" >> tests/test_main.py

      # Create README
      echo "# $project_name" > README.md
      echo "" >> README.md
      echo "A Python project created with Nix development environment." >> README.md
      echo "" >> README.md
      echo "## Development" >> README.md
      echo "" >> README.md
      echo "This project uses Poetry for dependency management and Nix for the development environment." >> README.md
      echo "" >> README.md
      echo "### Quick start" >> README.md
      echo "" >> README.md
      echo "```bash" >> README.md
      echo "# Install dependencies" >> README.md
      echo "poetry install" >> README.md
      echo "" >> README.md
      echo "# Run the main module" >> README.md
      echo "poetry run python -m src.$project_name" >> README.md
      echo "" >> README.md
      echo "# Run tests" >> README.md
      echo "poetry run pytest" >> README.md
      echo "```" >> README.md

      # Initialize git repository
      echo "📦 Initializing git repository..."
      git init -b main
      git add .
      git commit -m "Initial commit: Python project setup with Poetry"

      # Automatically allow direnv
      echo "🔒 Allowing direnv..."
      direnv allow

      echo "✅ Project '$project_name' ready! Environment activated."
      echo "💡 Run 'poetry install' to install dependencies"
      echo "💡 Run 'poetry run python -m src.$project_name' to run the main module"
      echo "💡 Run 'poetry run pytest' to run tests"
      echo "🔗 Git repository initialized with initial commit"
    '';
  };

  programs.ghostty = {
    enable = true;
    package = inputs.ghostty.packages.${pkgs.system}.default;

    enableFishIntegration = true;

    settings = {
      # theme = "miasma";
      theme = "Gruvbox Dark";
      font-size = 21;
      mouse-hide-while-typing = true;
      window-decoration = "auto";
      window-inherit-working-directory = true;
      app-notifications = "no-clipboard-copy";
      working-directory = "home";
      background = "#1f1f1f";
      background-opacity = 1;
      gtk-wide-tabs = false;
      shell-integration = "fish";
      cursor-color = "#458588";
      copy-on-select = "clipboard";
      gtk-tabs-location = "bottom";
      gtk-custom-css = "/home/misha/nixos-dotfiles/home/modules/shell/ghostty-gruvbox-tabs.css";

      custom-shader = [
        "shaders/sonic_boom_cursor.glsl"
        "shaders/cursor_warp.glsl"
      ];
      custom-shader-animation = true;

      # Replicate Zellij keybinds using Ghostty functionality
      keybind = [
        "ctrl+enter=ignore"

        # Tab management (replaces Zellij tabs)
        "alt+right=next_tab" # Next tab
        "alt+left=previous_tab" # Previous tab
        "alt+n=new_tab" # New tab

        "alt+d=close_tab" # Close tab
      ];
    };
  };
}
