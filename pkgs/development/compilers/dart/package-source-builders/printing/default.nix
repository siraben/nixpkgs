{
  lib,
  stdenv,
  pdfium,
  replaceVars,
}:

{ version, src, ... }:

stdenv.mkDerivation (finalAttrs: {
  pname = "printing";
  inherit version src;
  inherit (finalAttrs.src) passthru;

  prePatch = ''
    if [ -d printing ]; then pushd printing; fi
  '';

  patches = [
    (replaceVars ./printing.patch {
      pdfiumLib = lib.getLib pdfium;
      pdfiumDev = lib.getDev pdfium;
    })
  ];

  postPatch = ''
    popd || true
  '';

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    cp -r . $out

    runHook postInstall
  '';
})
