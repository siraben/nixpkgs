{
  lib,
  stdenv,
  fetchFromGitHub,
  libdeflate,
  cmake,
  doxygen,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "ptex";
  version = "2.5.4";

  src = fetchFromGitHub {
    owner = "wdas";
    repo = "ptex";
    rev = "v${finalAttrs.version}";
    sha256 = "sha256-DeOwigjCh6dMuGQCAR/+x+zMWqks5QhhNu+0LPDx6dY=";
  };

  postPatch = ''
    substituteInPlace src/build/ptex-config.cmake \
      --replace-fail "find_package(ZLIB REQUIRED)" "find_dependency(libdeflate REQUIRED)"
    substituteInPlace src/build/ptex.pc.in \
      --replace-fail "Requires.private: @pc_req_private@" "Requires.private: libdeflate" \
      --replace-fail "Version: @PROJECT_VERSION@" "Version: @PTEX_VER_STRIPPED@"
  '';

  outputs = [
    "bin"
    "dev"
    "out"
    "lib"
  ];

  nativeBuildInputs = [
    cmake
    doxygen
  ];
  propagatedBuildInputs = [ libdeflate ];

  cmakeFlags = [ (lib.cmakeFeature "PTEX_VER" "v${finalAttrs.version}") ];

  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  meta = {
    description = "Per-Face Texture Mapping for Production Rendering";
    mainProgram = "ptxinfo";
    homepage = "http://ptex.us/";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.all;
    maintainers = [ lib.maintainers.guibou ];
  };
})
