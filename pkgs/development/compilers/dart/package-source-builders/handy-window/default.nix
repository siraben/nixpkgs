{
  stdenv,
  lib,
  writeScript,
  cairo,
  fribidi,
}:

{ version, src, ... }:

stdenv.mkDerivation (finalAttrs: {
  pname = "handy-window";
  inherit version src;
  inherit (finalAttrs.src) passthru;

  setupHook = writeScript "handy-window-setup-hook" ''
    handyWindowConfigureHook() {
      export CFLAGS="$CFLAGS -isystem ${lib.getDev fribidi}/include/fribidi -isystem ${lib.getDev cairo}/include"
    }

    postConfigureHooks+=(handyWindowConfigureHook)
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    ln -s '${finalAttrs.src}'/* "$out"

    runHook postInstall
  '';
})
