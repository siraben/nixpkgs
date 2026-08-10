{
  stdenv,
  lib,
  writeScript,
  openssl,
}:

{ version, src, ... }:

stdenv.mkDerivation (finalAttrs: {
  pname = "matrix";
  inherit version src;
  inherit (finalAttrs.src) passthru;

  setupHook = writeScript "matrix-setup-hook" ''
    matrixFixupHook() {
      runtimeDependencies+=('${lib.getLib openssl}')
    }

    preFixupHooks+=(matrixFixupHook)
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    ln -s '${finalAttrs.src}'/* "$out"

    runHook postInstall
  '';
})
