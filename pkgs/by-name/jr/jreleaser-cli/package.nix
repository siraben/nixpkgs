{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  jre,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "jreleaser-cli";
  version = "1.25.0";

  src = fetchurl {
    url = "https://github.com/jreleaser/jreleaser/releases/download/v${finalAttrs.version}/jreleaser-tool-provider-${finalAttrs.version}.jar";
    hash = "sha256-ixcHrzCX+b1iEkmk2rWZidFBtT2Ar58pRSGLzwaDYSM=";
  };

  nativeBuildInputs = [ makeWrapper ];

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/share/java/ $out/bin/
    cp $src $out/share/java/jreleaser-cli.jar
    makeWrapper ${jre}/bin/java $out/bin/jreleaser-cli \
      --add-flags "-jar $out/share/java/jreleaser-cli.jar"
  '';

  meta = {
    homepage = "https://jreleaser.org/";
    description = "Release projects quickly and easily";
    sourceProvenance = [ lib.sourceTypes.binaryBytecode ];
    license = lib.licenses.asl20;
    maintainers = [ lib.maintainers.i-al-istannen ];
    mainProgram = "jreleaser-cli";
  };
})
