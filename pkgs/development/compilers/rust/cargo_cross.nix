{
  runCommand,
  stdenv,
  lib,
  pkgsBuildBuild,
  makeShellWrapper,
  rustc,
  auditable ? null,
  ...
}:

let
  # Preserve native Cargo's default unless explicitly overridden.
  cargo =
    if auditable == null then
      pkgsBuildBuild.cargo
    else
      pkgsBuildBuild.cargo.override { inherit auditable; };
in
runCommand "${stdenv.targetPlatform.config}-cargo-${lib.getVersion cargo}"
  {
    # Use depsBuildBuild or it tries to use target-runtimeShell
    depsBuildBuild = [ makeShellWrapper ];

    inherit (cargo) meta;
  }
  ''
    mkdir -p $out/bin
    ln -s ${cargo}/share $out/share

    makeWrapper "${cargo}/bin/cargo" "$out/bin/cargo" \
      --prefix PATH : "${rustc}/bin"
  ''
