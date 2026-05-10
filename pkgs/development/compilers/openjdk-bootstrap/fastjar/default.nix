{
  lib,
  stdenv,
  fetchurl,
  zlib,
}:

# Pure-C `jar` substitute used by java-gcj-compat (gcj's gjar is incomplete).

stdenv.mkDerivation {
  pname = "fastjar";
  version = "0.98";

  src = fetchurl {
    url = "https://download.savannah.nongnu.org/releases/fastjar/fastjar-0.98.tar.gz";
    hash = "sha512-wPn8p7WNas0AuQpRhNvem6P/xb9NaVEnQ+RQZJonK68favmLFdedK1OZDq+E70AsmGA15rYVoZ417UJDSBQ5Aw==";
  };

  patches = [
    ./patches/0001-Properly-zero-terminate-filename.patch
    ./patches/0002-Fix-write-return-value-check.patch
  ];

  buildInputs = [ zlib ];

  enableParallelBuilding = true;

  meta = {
    description = "Fast implementation of the Java jar tool";
    homepage = "https://savannah.nongnu.org/projects/fastjar/";
    license = lib.licenses.gpl2Plus;
    mainProgram = "fastjar";
    platforms = [
      "x86_64-linux"
      "i686-linux"
    ];
  };
}
