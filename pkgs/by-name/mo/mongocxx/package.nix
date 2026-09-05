{
  lib,
  stdenv,
  fetchFromGitHub,
  mongoc_2,
  openssl,
  cyrus_sasl,
  cmake,
  validatePkgConfig,
  testers,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "mongocxx";
  version = "4.5.2";

  src = fetchFromGitHub {
    owner = "mongodb";
    repo = "mongo-cxx-driver";
    tag = "r${finalAttrs.version}";
    hash = "sha256-KardlFJ4tC9PgYWf/1198BVjJMPdSRS8n6QxUUwN2z0=";
  };

  postPatch = ''
    substituteInPlace src/bsoncxx/cmake/libbsoncxx.pc.in \
      src/mongocxx/cmake/libmongocxx.pc.in \
      --replace "\''${prefix}/" ""
  '';

  nativeBuildInputs = [
    cmake
    validatePkgConfig
  ];

  buildInputs = [
    mongoc_2
    openssl
    cyrus_sasl
  ];

  cmakeFlags = [
    "-DCMAKE_CXX_STANDARD=20"
    "-DBUILD_VERSION=${finalAttrs.version}"
    "-DENABLE_UNINSTALL=OFF"
  ];

  passthru.tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;

  meta = {
    description = "Official C++ client library for MongoDB";
    homepage = "http://mongocxx.org";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [
      adriandole
      vcele
    ];
    pkgConfigModules = [
      "libmongocxx1"
      "libbsoncxx1"
    ];
    platforms = lib.platforms.all;
  };
})
