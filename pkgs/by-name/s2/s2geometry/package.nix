{
  abseil-cpp_202508,
  cmake,
  fetchFromGitHub,
  gbenchmark,
  gtest,
  stdenv,
  lib,
  pkg-config,
  openssl,
}:

let
  cxxStandard = "17";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "s2geometry";
  version = "0.14.0";

  src = fetchFromGitHub {
    owner = "google";
    repo = "s2geometry";
    tag = "v${finalAttrs.version}";
    hash = "sha256-mdwxHgpnyyBX/hYiK43b8Qae5ffEZQZ9fVQlerX43VA=";
  };

  patches = [ ./use-system-test-dependencies.patch ];

  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace-fail "VERSION 0.12.0" "VERSION ${finalAttrs.version}"
  '';

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  cmakeFlags = [
    (lib.cmakeFeature "CMAKE_CXX_STANDARD" cxxStandard)
    (lib.cmakeBool "BUILD_TESTS" finalAttrs.finalPackage.doCheck)
  ];

  checkInputs = [
    gbenchmark
    gtest
    openssl
  ];

  propagatedBuildInputs = [
    (abseil-cpp_202508.override { inherit cxxStandard; })
  ];

  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  meta = {
    changelog = "https://github.com/google/s2geometry/releases/tag/v${finalAttrs.version}";
    description = "Computational geometry and spatial indexing on the sphere";
    homepage = "http://s2geometry.io/";
    license = lib.licenses.asl20;
    maintainers = [ lib.maintainers.Thra11 ];
    platforms = lib.platforms.unix;
  };
})
