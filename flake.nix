{
  description = "A Nix-flake-based Node.js development environment";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1"; # unstable Nixpkgs
    nixpkgs-node.url = "github:NixOS/nixpkgs/080a4a27f206d07724b88da096e27ef63401a504"; # nodejs_18 == 18.19.1
    nixpkgs-npm.url = "github:NixOS/nixpkgs/2d38b664b4400335086a713a0036aafaa002c003"; # nodePackages.npm == 9.2.0
  };

  outputs =
    { self, ... }@inputs:

    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forEachSupportedSystem =
        f:
        inputs.nixpkgs.lib.genAttrs supportedSystems (
          system:
          f {
            inherit system;
            pkgs = import inputs.nixpkgs {
              inherit system;
              overlays = [ inputs.self.overlays.default ];
            };
          }
        );
    in
    {
      overlays.default = final: prev: rec {
        nodejs = inputs.nixpkgs-node.legacyPackages.${prev.system}.nodejs_18;
        npm = inputs.nixpkgs-npm.legacyPackages.${prev.system}.nodePackages.npm;
        yarn = (prev.yarn.override { inherit nodejs; });
      };

      devShells = forEachSupportedSystem (
        { pkgs, system }:
        {
          default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              nodejs
              npm
              pnpm
              yarn
              python312
              self.formatter.${system}
            ];

            # nodejs bundles its own npm; force the pinned npm (9.2.0) first on PATH
            shellHook = ''
              export PATH="${pkgs.npm}/bin:$PATH"
            '';
          };
        }
      );

      formatter = forEachSupportedSystem ({ pkgs, ... }: pkgs.nixfmt);
    };
}
