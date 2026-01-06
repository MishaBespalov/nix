{
  description = "Go development environment";

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
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            # Go toolchain
            unstable.go
            unstable.gopls
            unstable.go-tools
            unstable.golangci-lint
            unstable.delve
            
            # Additional tools
            pkgs.gcc
            pkgs.pkg-config
          ];
          
          # Environment variables
          GOROOT = "${unstable.go}/share/go";
        };
      });
}