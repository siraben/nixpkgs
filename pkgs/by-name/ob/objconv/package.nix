{
  lib,
  stdenv,
  fetchurl,
  unzip,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "objconv";
  version = "2.57";

  src = fetchurl {
    # Versioned archive maintained by the FreeBSD port maintainer.
    url = "http://fuz.ooo/pub/objconv/objconv-${finalAttrs.version}.zip";
    hash = "sha256-D2BPk/l/aJr9dhXIYXbrFbyVAB6t+DF/F+vQmcUMWeE=";
  };

  nativeBuildInputs = [ unzip ];

  outputs = [
    "out"
    "doc"
  ];

  unpackPhase = ''
    mkdir -p "$name"
    cd "$name"
    unpackFile "$src"
    unpackFile source.zip
  '';

  buildPhase = "c++ -o objconv -O2 *.cpp";

  installPhase = ''
    mkdir -p $out/bin $out/doc/objconv
    mv objconv $out/bin
    mv objconv-instructions.pdf $out/doc/objconv
  '';

  meta = {
    description = "Object and executable file converter, modifier and disassembler";
    mainProgram = "objconv";
    homepage = "https://www.agner.org/optimize/";
    license = lib.licenses.gpl3Only;
    maintainers = [ ];
    platforms = lib.platforms.unix;
  };
})
