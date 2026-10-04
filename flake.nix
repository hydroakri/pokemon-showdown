{
  description = "A Nix-flake-based Node.js development environment";

  inputs = {
    # Pinned directly to github: rather than flakehub.com -- flakehub's IPv6
    # endpoint has been unreachable on this network; github/cache.nixos.org
    # work fine. Same revision already used by the other flakes in this
    # project.
    #
    # A single nixpkgs revision is used for everything now. It previously
    # mixed in two older, separately-pinned nixpkgs snapshots via an overlay
    # to get an exact nodejs_18/npm 9.2.0 pair -- that cross-revision mixing
    # produced a real ABI break on aarch64 (the old npm's nodejs binary
    # requiring a glibc older than what this revision's gcc-lib -- pulled in
    # by other packages sharing the shell, e.g. the nixfmt formatter --
    # provides). x86_64's binary cache happened to paper over it, aarch64
    # didn't. package.json only requires node >=16, so this revision's
    # current LTS (nodejs_22, bundled npm) is simpler and actually works on
    # both architectures.
    nixpkgs.url = "github:NixOS/nixpkgs/e2587caef70cea85dd97d7daab492899902dbf5d";
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
            pkgs = import inputs.nixpkgs { inherit system; };
          }
        );
    in
    {
      devShells = forEachSupportedSystem (
        { pkgs, system }:
        {
          default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              nodejs_22
              pnpm
              (yarn.override { nodejs = nodejs_22; })
              python312
              self.formatter.${system}
            ];
          };
        }
      );

      formatter = forEachSupportedSystem ({ pkgs, ... }: pkgs.nixfmt);
    };
}
