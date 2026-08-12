{
  fetchFromGitHub,
  fetchpatch,
  lib,
  stdenv,
  cmake,
  buildPackages,
  asciidoc,
  libxslt,
}:

let
  isCrossCompiling = stdenv.hostPlatform != stdenv.buildPlatform;
in

stdenv.mkDerivation (finalAttrs: {
  pname = "scas";
  version = "0.5.5";

  src = fetchFromGitHub {
    owner = "KnightOS";
    repo = "scas";
    rev = finalAttrs.version;
    sha256 = "sha256-JGQE+orVDKKJsTt8sIjPX+3yhpZkujISroQ6g19+MzU=";
  };

  patches = [
    (fetchpatch {
      url = "https://github.com/KnightOS/scas/commit/f3988ea3f6ca93d5373281fecc24acf97c457266.patch";
      hash = "sha256-cDfl+InO+F28P6XRNRWy/duI7B0PRPD4GPgoG0p96qA=";
      excludes = [ "common/instructions.c" ];
    })
  ];

  cmakeFlags = [ "-DSCAS_LIBRARY=1" ];
  postPatch = ''
    substituteInPlace common/instructions.c \
      --replace-fail '#include <string.h>' $'#include <string.h>\n#include <strings.h>'
    substituteInPlace linker/linker.c \
      --replace-fail '#include <stdio.h>' $'#include <stdio.h>\n#include <strings.h>'
    substituteInPlace CMakeLists.txt \
      --replace-fail "TARGETS scas scdump scwrap" "TARGETS scas scdump scwrap generate_tables" \
      --replace-fail "cmake_minimum_required(VERSION 2.8.5)" "cmake_minimum_required(VERSION 3.10)"
  '';
  strictDeps = true;

  depsBuildBuild = lib.optionals isCrossCompiling [ buildPackages.knightos-scas ];
  nativeBuildInputs = [
    asciidoc
    libxslt.bin
    cmake
  ];

  postInstall = ''
    cd ..
    make DESTDIR=$out install_man
  '';

  meta = {
    homepage = "https://knightos.org/";
    description = "Assembler and linker for the Z80";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ siraben ];
    platforms = lib.platforms.all;
  };
})
