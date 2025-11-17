{
  lib,
  stdenv,
  fetchurl,
  buildPackages,
}:

stdenv.mkDerivation rec {
  pname = "cccc";
  version = "3.1.4";

  src = fetchurl {
    url = "mirror://sourceforge/cccc/${version}/cccc-${version}.tar.gz";
    sha256 = "1gsdzzisrk95kajs3gfxks3bjvfd9g680fin6a9pjrism2lyrcr7";
  };

  hardeningDisable = [ "format" ];

  patches = [ ./cccc.patch ];

  depsBuildBuild = [ buildPackages.stdenv.cc ];

  preConfigure = ''
    substituteInPlace install/install.mak --replace /usr/local/bin $out/bin
    substituteInPlace install/install.mak --replace MKDIR=mkdir "MKDIR=mkdir -p"

    # Remove test and install from default target to avoid running cross-compiled binary
    substituteInPlace makefile --replace-fail 'all : pccts cccc test install' 'all : pccts cccc'
  '';

  # Build pccts (antlr/dlg) with native compiler since they run during build
  # Build cccc itself with cross compiler
  preBuild = ''
    # Build pccts with native compiler
    make -C pccts CC=${buildPackages.stdenv.cc}/bin/cc
  '';

  buildFlags = [
    "CCC=${stdenv.cc.targetPrefix}c++"
    "LD=${stdenv.cc.targetPrefix}c++"
  ];

  buildTargets = [ "cccc" ];

  # Tests try to run the compiled binary, which fails during cross-compilation
  doCheck = false;

  installPhase = ''
    runHook preInstall
    install -Dm755 cccc/cccc -t $out/bin
    runHook postInstall
  '';

  meta = {
    description = "C and C++ Code Counter";
    mainProgram = "cccc";
    longDescription = ''
      CCCC is a tool which analyzes C++ and Java files and generates a report
      on various metrics of the code. Metrics supported include lines of code, McCabe's
      complexity and metrics proposed by Chidamber&Kemerer and Henry&Kafura.
    '';
    homepage = "https://cccc.sourceforge.net/";
    license = lib.licenses.gpl2;
    platforms = lib.platforms.unix;
    maintainers = [ ];
    # The last successful Darwin Hydra build was in 2023
    broken = stdenv.hostPlatform.isDarwin;
  };
}
