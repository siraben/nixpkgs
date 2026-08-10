{
  stdenv,
  libayatana-appindicator,
}:

{ version, src, ... }:

stdenv.mkDerivation (finalAttrs: {
  pname = "system-tray";
  inherit version src;
  inherit (finalAttrs.src) passthru;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    cp -r '${finalAttrs.src}'/* "$out"
    substituteInPlace "$out/linux/tray.cc" \
      --replace "libappindicator3.so.1" "${libayatana-appindicator}/lib/libayatana-appindicator3.so.1"

    runHook postInstall
  '';
})
