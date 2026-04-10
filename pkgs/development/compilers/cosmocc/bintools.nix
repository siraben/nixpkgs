{
  lib,
  stdenv,
  runCommand,
  cosmocc,
  cosmoArch ? "x86_64",
}:

let
  targetPrefix = lib.optionalString (
    stdenv.hostPlatform != stdenv.targetPlatform
  ) "${stdenv.targetPlatform.config}-";
in
runCommand "cosmocc-bintools-${cosmoArch}-${cosmocc.version}"
  {
    pname = "cosmocc-bintools";
    inherit (cosmocc) version;

    passthru = {
      isCosmopolitan = true;
      inherit targetPrefix;
    };

    meta = cosmocc.meta // {
      description = "Cosmopolitan bintools for ${cosmoArch} (linker, archiver, etc.)";
    };
  }
  ''
    mkdir -p $out/bin
    # Use the actual binaries, not the cosmo* wrapper scripts which use
    # BIN-relative paths that break when wrapped by bintools-wrapper.
    for tool in ar ranlib ld ld.bfd objcopy objdump nm size strings readelf strip; do
      ln -s ${cosmocc}/bin/${cosmoArch}-linux-cosmo-$tool $out/bin/${targetPrefix}$tool
      # Also create unprefixed symlinks so GCC's collect2 finds them
      # (GCC searches for e.g. 'ld.bfd', not 'x86_64-unknown-linux-gnu-ld.bfd')
      ln -sf ${cosmocc}/bin/${cosmoArch}-linux-cosmo-$tool $out/bin/$tool
    done
  ''
