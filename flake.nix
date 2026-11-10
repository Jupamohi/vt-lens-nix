{
  description = "Nix packaging for VT Lens, a native GUI to inspect local processes and network connections";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Código fuente de VT Lens, fijado a un tag. 
    # Para actualizar a otra versión: cambia el tag aquí y ejecuta `nix flake update vt-lens-src`.
    vt-lens-src = {
      url = "github:ValentinTorassa/VT-Lens/v0.3.0";
      flake = false;
    };
  };

  outputs =
    { self, nixpkgs, vt-lens-src }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: rec {
        vt-lens = pkgs.callPackage ./package.nix { src = vt-lens-src; };
        default = vt-lens;
      });

      apps = forAllSystems (pkgs: {
        default = {
          type = "app";
          program = "${self.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/vt-lens";
        };
      });

      overlays.default = final: _prev: {
        vt-lens = final.callPackage ./package.nix { src = vt-lens-src; };
      };
    };
}
