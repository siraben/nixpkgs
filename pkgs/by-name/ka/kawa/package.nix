{
  lib,
  stdenv,
  fetchzip,
  jre,
  makeWrapper,
}:

stdenv.mkDerivation rec {
  pname = "kawa";
  version = "3.1.1";

  src = fetchzip {
    url = "mirror://gnu/kawa/kawa-${version}.zip";
    sha256 = "sha256-/9MiOak/Io/UTR8gylTZWdVFKlZooy5R0yRGK+OeJ04=";
  };

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/java
    cp -r lib/* $out/share/java/

    mkdir -p $out/bin
    makeWrapper ${jre}/bin/java $out/bin/kawa \
      --add-flags "-jar $out/share/java/kawa.jar"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Scheme implementation running on the Java platform";
    longDescription = ''
      Kawa is a general-purpose programming language that runs on the Java platform.
      It aims to combine the benefits of dynamic scripting languages (less boiler-plate
      code, fast and easy start-up, a REPL, no required compilation step) with the
      benefits of traditional compiled languages (fast execution, static error detection,
      modularity, zero-overhead Java platform integration).
    '';
    homepage = "https://www.gnu.org/software/kawa/";
    license = licenses.mit;
    maintainers = with maintainers; [ siraben ];
    platforms = platforms.all;
  };
}
