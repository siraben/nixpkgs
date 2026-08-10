{
  lib,
  stdenv,
  fetchurl,
  jre_headless,
  makeWrapper,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "trino-cli";
  version = "476";

  jarfilename = "trino-cli-${finalAttrs.version}-executable.jar";

  nativeBuildInputs = [ makeWrapper ];

  src = fetchurl {
    url = "mirror://maven/io/trino/trino-cli/${finalAttrs.version}/${finalAttrs.jarfilename}";
    sha256 = "sha256-/k6cf7VpzWdnOvoWIpRfYwjh5ZvbglQZNSuAiHZhdXs=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -D "$src" "$out/share/java/${finalAttrs.jarfilename}"

    makeWrapper ${jre_headless}/bin/java $out/bin/trino \
      --add-flags "-jar $out/share/java/${finalAttrs.jarfilename}"

    runHook postInstall
  '';

  meta = {
    description = "Trino CLI provides a terminal-based, interactive shell for running queries";
    mainProgram = "trino";
    homepage = "https://github.com/trinodb/trino";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [
      regadas
      cpcloud
    ];
  };
})
