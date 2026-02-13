{
  description = "NixOS + Home Manager + NixVim";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
    };

    zig.url = "github:mitchellh/zig-overlay";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    xremap-flake = {
      url = "github:xremap/nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    nixvim,
    xremap-flake,
    zig,
    rust-overlay,
    flake-utils,
    ...
  } @ inputs:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system}.extend rust-overlay.overlays.default;
      zigPkg = zig.packages.${system};
    in {
      devShells.default = pkgs.mkShell {
        buildInputs = [
          zigPkg.default # latest stable release
          # or zigPkg.master # latest master
        ];
      };
    })
    // {
      nixosConfigurations.nixos-btw = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          xremap-flake.nixosModules.default
          home-manager.nixosModules.home-manager
          {
            # Apply rust-overlay to the system packages
            nixpkgs.overlays = [ rust-overlay.overlays.default ];
            
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;

              # your user config lives in ./home.nix
              users.misha = {...}: {
                imports = [./home.nix];
                _module.args = {inherit inputs;};
              };

              # expose NixVim options to Home Manager
              sharedModules = [
                nixvim.homeModules.nixvim
              ];

              # back up conflicting files instead of failing
              backupFileExtension = "backup";
            };
          }
        ];
      };

      templates = {
        zig = {
          path = ./templates/zig;
          description = "Zig development environment";
        };
        rust = {
          path = ./templates/rust;
          description = "Rust development environment";
        };
        python = {
          path = ./templates/python;
          description = "Python development environment";
        };
        go = {
          path = ./templates/go;
          description = "Go development environment";
        };
      };
    };
}
