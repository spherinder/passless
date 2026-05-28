{ pkgs, crane, src, rustToolchain, withTpm ? false }:
let
  craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;
  customFilter = path: type:
    (builtins.match ".*/LICENSE$" path != null)
    || (craneLib.filterCargoSources path type);
  commonArgs = {
    src = pkgs.lib.cleanSourceWith {
      inherit src;
      filter = customFilter;
      name = "passless-src";
    };
    pname = "passless";
    version = "0.11.1";
    cargoExtraArgs = "--package passless-rs" + pkgs.lib.optionalString withTpm " --features tpm";
    # e2e integration tests need a running authenticator + UHID
    cargoTestExtraArgs = "--bins";
    strictDeps = true;
    nativeBuildInputs = [ pkgs.installShellFiles pkgs.pkg-config ];
    buildInputs = [ pkgs.libudev-zero ]
      ++ pkgs.lib.optionals withTpm [ pkgs.tpm2-tss ];
  };
  cargoArtifacts = craneLib.buildDepsOnly commonArgs;
in
craneLib.buildPackage (commonArgs // {
  inherit cargoArtifacts;
  postInstall = ''
    patchelf --add-rpath ${pkgs.lib.makeLibraryPath [ pkgs.libudev-zero ]} $out/bin/passless
    completions=$(find target -type d -name completions -path '*passless-rs*' | head -n1)
    if [ -n "$completions" ]; then
      installShellCompletion \
        --bash "$completions/passless.bash" \
        --zsh  "$completions/_passless" \
        --fish "$completions/passless.fish"
    fi
  '';
  meta = {
    description = "FIDO2 security token emulator";
    homepage = "https://github.com/pando85/passless";
    mainProgram = "passless";
  };
})
