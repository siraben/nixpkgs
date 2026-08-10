{
  fetchPypi,
  unzip,
  stdenv,
  pname,
  version,
  jarHash,
}:

stdenv.mkDerivation (finalAttrs: {
  inherit pname version;

  src = fetchPypi {
    pname = finalAttrs.pname;
    inherit (finalAttrs) version;
    format = "wheel";
    python = "py3";
    dist = "py3";
    hash = jarHash;
  };

  dontUnpack = true;

  nativeBuildInputs = [ unzip ];

  installPhase = ''
    unzip ${finalAttrs.src}
    install -D ./skein/java/skein.jar $out
  '';
})
