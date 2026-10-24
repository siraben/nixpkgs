{
  lib,
  stdenv,
  cmake,
  ninja,
  python3,
  versionCheckHook,
  src,
  version,
}:

stdenv.mkDerivation {
  pname = "qtwebengine-gn";
  inherit version src;

  strictDeps = true;
  cmakeDir = "../src/gn";

  # Keep format diagnostics enabled for Nixpkgs's format-security hardening.
  postPatch = ''
    substituteInPlace src/3rdparty/gn/build/gen.py \
      --replace-fail "'-Wno-format'," "'-Wformat',"
  '';
  nativeBuildInputs = [
    cmake
    ninja
    python3
  ];

  # Qt's standalone GN build invokes a nested Ninja during the build.
  preConfigure = ''
    export NINJAFLAGS="-j$NIX_BUILD_CORES"
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];

  meta = {
    description = "Qt WebEngine's matching GN build tool";
    mainProgram = "gn";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.unix;
  };
}
