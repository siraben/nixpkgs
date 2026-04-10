{
  lib,
  stdenv,
  runCommand,
  cosmocc,
  makeWrapper,
}:

let
  targetPrefix = lib.optionalString (
    stdenv.hostPlatform != stdenv.targetPlatform
  ) "${stdenv.targetPlatform.config}-";
in
runCommand "cosmocc-bintools-fat-${cosmocc.version}"
  {
    pname = "cosmocc-bintools-fat";
    inherit (cosmocc) version;

    nativeBuildInputs = [ makeWrapper ];

    passthru = {
      isCosmopolitan = true;
      inherit targetPrefix;
    };

    meta = cosmocc.meta // {
      description = "Cosmopolitan fat bintools (linker, archiver, etc.)";
    };
  }
  # cosmoar is a shell script that creates both x86_64 and aarch64
  # archives in parallel. It uses BIN=${0%/*} so we need makeWrapper.
  ''
    mkdir -p $out/bin
    makeWrapper "${cosmocc}/bin/cosmoar" "$out/bin/${targetPrefix}ar"
    # cosmoranlib just calls x86_64 ranlib; use it directly
    ln -s ${cosmocc}/bin/x86_64-linux-cosmo-ranlib $out/bin/${targetPrefix}ranlib
    # For ld, strip, etc. use x86_64 versions - the fat compiler handles
    # dual-arch linking via cosmocc itself, not directly through ld.
    for tool in ld ld.bfd objcopy objdump nm size strings readelf strip; do
      ln -s ${cosmocc}/bin/x86_64-linux-cosmo-$tool $out/bin/${targetPrefix}$tool
      ln -sf ${cosmocc}/bin/x86_64-linux-cosmo-$tool $out/bin/$tool
    done
  ''
