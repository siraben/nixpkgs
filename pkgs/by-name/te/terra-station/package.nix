{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  makeWrapper,
  electron,
  asar,
}:

let
  inherit (stdenv.hostPlatform) system;

  throwSystem = throw "Unsupported system: ${stdenv.hostPlatform.system}";

  sha256 =
    {
      "x86_64-linux" = "139nlr191bsinx6ixpi2glcr03lsnzq7b0438h3245napsnjpx6p";
    }
    ."${system}" or throwSystem;

  arch =
    {
      "x86_64-linux" = "amd64";
    }
    ."${system}" or throwSystem;

in

stdenv.mkDerivation (finalAttrs: {
  pname = "terra-station";
  version = "1.2.0";

  src = fetchurl {
    url = "https://github.com/terra-money/station-desktop/releases/download/v${finalAttrs.version}/Terra.Station_${finalAttrs.version}_${arch}.deb";
    inherit sha256;
  };

  nativeBuildInputs = [
    makeWrapper
    asar
    dpkg
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/terra-station

    cp -a usr/share/* $out/share
    cp -a "opt/Terra Station/"{locales,resources} $out/share/terra-station

    # patch pre-built node modules
    asar e $out/share/terra-station/resources/app.asar asar-unpacked
    find asar-unpacked -name '*.node' -exec patchelf \
      --add-rpath "${lib.makeLibraryPath [ stdenv.cc.cc ]}" \
      {} \;
    asar p asar-unpacked $out/share/terra-station/resources/app.asar

    substituteInPlace $out/share/applications/station-electron.desktop \
      --replace "/opt/Terra Station/station-electron" terra-station

    runHook postInstall
  '';

  postFixup = ''
    makeWrapper ${electron}/bin/electron $out/bin/terra-station \
      --add-flags $out/share/terra-station/resources/app.aasar
  '';

  meta = {
    description = "Terra station is the official wallet of the Terra blockchain";
    homepage = "https://station.money/";
    license = lib.licenses.isc;
    maintainers = [ lib.maintainers.peterwilli ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "terra-station";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
