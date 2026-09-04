{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  ninja,
  perl,
  zlib,
  libxml2,
  eigen,
  python3,
  cairo,
  pkg-config,
  swig,
  rapidjson,
  boost,
  maeparser,
  coordgenlibs,
  ctestCheckHook,
}:

stdenv.mkDerivation {
  pname = "openbabel";
  version = "3.2.1";

  src = fetchFromGitHub {
    owner = "openbabel";
    repo = "openbabel";
    tag = "openbabel-3-2-1";
    hash = "sha256-B1jHLv4Aht9vS1YnIPCfOtZjD5Kkfg51qJbDq6u3PnM=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    swig
    pkg-config
  ];

  buildInputs = [
    perl
    zlib
    libxml2
    eigen
    python3
    cairo
    rapidjson
    boost
    maeparser
    coordgenlibs
  ];

  nativeCheckInputs = [
    ctestCheckHook
  ];

  cmakeFlags = [
    (lib.cmakeBool "RUN_SWIG" true)
    (lib.cmakeBool "PYTHON_BINDINGS" true)
    (lib.cmakeFeature "PYTHON_INSTDIR" "${placeholder "out"}/${python3.sitePackages}")
  ];

  disabledTests = [
    "test_cifspacegroup_11"
    "pybindtest_obconv_writers"
    # These tests fail with GCC 15
    "test_align_4"
    "test_align_5"
  ];

  doCheck = true;

  dontUseNinjaCheck = true;

  meta = {
    description = "Toolbox designed to speak the many languages of chemical data";
    homepage = "http://openbabel.org";
    platforms = lib.platforms.all;
    license = lib.licenses.gpl2Plus;
    maintainers = with lib.maintainers; [ danielbarter ];
  };
}
