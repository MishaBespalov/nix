{
  description = "Zig development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    zig.url = "github:mitchellh/zig-overlay";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, nixpkgs-unstable, zig, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        unstable = nixpkgs-unstable.legacyPackages.${system};
        zigPkg = zig.packages.${system};
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            zigPkg.default       # latest stable release
            # or zigPkg.master   # latest master
            unstable.zls         # Zig Language Server from unstable (latest available)
          ];
        };
      });
}