{
  lib,
  gccStdenv,
  fetchFromGitHub,
  buildPackages,
}:

gccStdenv.mkDerivation rec {
  pname = "cc65";
  version = "2.19";

  src = fetchFromGitHub {
    owner = "cc65";
    repo = "cc65";
    rev = "V${version}";
    sha256 = "01a15yvs455qp20hri2pbg2wqvcip0d50kb7dibi9427hqk9cnj4";
  };

  depsBuildBuild = [ buildPackages.stdenv.cc ];

  # cc65 builds tools (cc65, ca65, ld65) that run on the host, then uses them to build
  # 6502 libraries. For cross-compilation, we need to:
  # 1. Build the tools with the cross compiler (so they run on target platform)
  # 2. Skip libsrc build since we can't run cross-compiled tools during build
  postPatch = lib.optionalString (gccStdenv.hostPlatform != gccStdenv.buildPlatform) ''
    # Don't build libraries that require running the just-built tools
    # Remove libsrc from all targets (all, clean, install, etc.)
    sed -i '/@.*-C libsrc/d' Makefile
  '';

  makeFlags = [
    "PREFIX=${placeholder "out"}"
    "CROSS_COMPILE=${gccStdenv.cc.targetPrefix}"
  ];

  enableParallelBuilding = true;

  meta = with lib; {
    homepage = "https://cc65.github.io/";
    description = "C compiler for processors of 6502 family";
    longDescription = ''
      cc65 is a complete cross development package for 65(C)02 systems,
      including a powerful macro assembler, a C compiler, linker, librarian and
      several other tools.

      cc65 has C and runtime library support for many of the old 6502 machines,
      including the following Commodore machines:

      - VIC20
      - C16/C116 and Plus/4
      - C64
      - C128
      - CBM 510 (aka P500)
      - the 600/700 family
      - newer PET machines (not 2001).
      - the Apple ][+ and successors.
      - the Atari 8-bit machines.
      - the Atari 2600 console.
      - the Atari 5200 console.
      - GEOS for the C64, C128 and Apple //e.
      - the Bit Corporation Gamate console.
      - the NEC PC-Engine (aka TurboGrafx-16) console.
      - the Nintendo Entertainment System (NES) console.
      - the Watara Supervision console.
      - the VTech Creativision console.
      - the Oric Atmos.
      - the Oric Telestrat.
      - the Lynx console.
      - the Ohio Scientific Challenger 1P.

      The libraries are fairly portable, so creating a version for other 6502s
      shouldn't be too much work.
    '';
    license = licenses.zlib;
    maintainers = [ ];
    platforms = platforms.unix;
  };
}
