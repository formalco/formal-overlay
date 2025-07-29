{
  description = ''
    Formal Nix expressions
  '';

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      eachSystem =
        f:
        builtins.listToAttrs (
          builtins.map (system: {
            name = system;
            value = f {
              pkgs = nixpkgs.legacyPackages.${system};
              inherit system;
            };
          }) systems
        );
    in
    {
      packages = eachSystem (
        { pkgs, system, ... }: {
          formal = pkgs.callPackage ./pkgs/formal.nix { };
          default = self.packages.${system}.formal;
        }
      );

      homeManagerModules = import ./home-modules;

      overlays.default = import ./.;
    };
}
