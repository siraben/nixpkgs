{
  buildPythonPackage,
  cmake,
  dlib,
  pytestCheckHook,
  setuptools,
}:

buildPythonPackage.override { inherit (dlib) stdenv; } {
  inherit (dlib)
    pname
    version
    src
    nativeBuildInputs
    buildInputs
    cmakeFlags
    passthru
    meta
    ;

  patches = [ ./build-cores.patch ];

  pyproject = true;
  build-system = [
    cmake
    setuptools
  ];

  # PEP 517 does not use setupPyBuildFlags. Pass the same options as the
  # native library directly to setup.py's CMake invocation (notably disabling
  # the 32-bit ARM NEON flags on aarch64-darwin).
  postPatch = ''
    substituteInPlace setup.py \
      --replace-fail '_cmake_extra_options = []' \
        '_cmake_extra_options = ${builtins.toJSON dlib.cmakeFlags}'
  '';

  dontUseCmakeConfigure = true;

  nativeCheckInputs = [
    pytestCheckHook
  ];

  doCheck =
    !(
      # The tests attempt to use CUDA on the build platform.
      # https://github.com/NixOS/nixpkgs/issues/225912
      dlib.cudaSupport

      # although AVX can be enabled, we never test with it. Some Hydra machines
      # fail because of this, however their build results are probably used on hardware
      # with AVX support.
      || dlib.avxSupport
    );
}
