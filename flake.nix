{
  description = "dahlheim.ch";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

   outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs { inherit system; };
    in {
    devShells.default =
      pkgs.mkShell {
        packages = [
          pkgs.hugo
          pkgs.nodejs_20
          pkgs.nodePackages.tailwindcss
          pkgs.nodePackages.pnpm
          pkgs.ansible
        ];
      };
  });
}
