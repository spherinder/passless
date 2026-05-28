{
  description = "Passless - software FIDO2 authenticator emulator";
  inputs.fenix.url = "github:nix-community/fenix";
  inputs.crane.url = "github:ipetkov/crane";
  outputs = { self, nixpkgs, systems, fenix, crane, ... }: let
    eachSystem = f: nixpkgs.lib.genAttrs (import systems) (system: f {
      inherit system;
      pkgs = nixpkgs.legacyPackages.${system};
    });
  in {
    packages = eachSystem ({ pkgs, system, ... }: let
      rustToolchain = (fenix.packages.${system}.complete.withComponents [ "cargo" "rustc" ]);
      passless = pkgs.callPackage ./nix/package.nix {
        inherit crane rustToolchain;
        src = ./.;
      };
    in {
      default = passless;
      passless = passless;
      passless-tpm = pkgs.callPackage ./nix/package.nix {
        inherit crane rustToolchain;
        src = ./.;
        withTpm = true;
      };
    });
    devShells = eachSystem ({pkgs, ...}: {
      default = pkgs.mkShell {
        packages = with pkgs; [
          clang
          pkg-config
          libudev-zero
        ];
      };
    });
    nixosModules.default = import ./nix/module.nix { inherit self; };
  };
}
