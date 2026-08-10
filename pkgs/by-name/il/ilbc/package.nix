{
  lib,
  stdenv,
  fetchurl,
  gawk,
  cmake,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "ilbc-rfc3951";
  version = "0-unstable-2004-12-03";

  script = ./extract-cfile.awk;

  src = fetchurl {
    url = "https://www.ietf.org/rfc/rfc3951.txt";
    sha256 = "0zf4mvi3jzx6zjrfl2rbhl2m68pzbzpf1vbdmn7dqbfpcb67jpdy";
  };

  nativeBuildInputs = [ cmake ];

  unpackPhase = ''
    mkdir -v ilbc-rfc3951
    cd ilbc-rfc3951
    ${lib.getExe gawk} -f ${finalAttrs.script} $src
    cp -v ${./CMakeLists.txt} CMakeLists.txt
  '';

  # Fixes the build with CMake 4
  cmakeFlags = [
    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
  ];

  meta = {
    platforms = lib.platforms.unix;
    license = lib.licenses.free;
  };
})
