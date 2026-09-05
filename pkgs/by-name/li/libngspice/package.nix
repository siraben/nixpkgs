{
  lib,
  stdenv,
  fetchurl,
  flex,
  bison,
  fftw,
  withNgshared ? true,
  libsamplerate,
  libsndfile,
  libxaw,
  libxext,
  llvmPackages,
  readline,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "${lib.optionalString withNgshared "lib"}ngspice";
  version = "47";

  src = fetchurl {
    url = "mirror://sourceforge/ngspice/ngspice-${finalAttrs.version}.tar.gz";
    hash = "sha256-iU5kllHxg4oUCV5aVDnn06pj6H7eFNKDFz/aT83vZ18=";
  };

  nativeBuildInputs = [
    flex
    bison
  ];

  buildInputs = [
    fftw
    libsamplerate
    libsndfile
    readline
  ]
  ++ lib.optionals (!withNgshared) [
    libxaw
    libxext
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    llvmPackages.openmp
  ];

  configureFlags =
    lib.optionals withNgshared [
      "--with-ngshared"
    ]
    ++ [
      "--enable-xspice"
      "--enable-cider"
      "--enable-osdi"
    ];

  enableParallelBuilding = true;

  meta = {
    description = "Next Generation Spice (Electronic Circuit Simulator)";
    mainProgram = "ngspice";
    homepage = "http://ngspice.sourceforge.net";
    license = with lib.licenses; [
      bsd3
      gpl2Plus
      lgpl2Plus
    ]; # See https://sourceforge.net/p/ngspice/ngspice/ci/master/tree/COPYING
    maintainers = with lib.maintainers; [ bgamari ];
    platforms = lib.platforms.unix;
  };
})
