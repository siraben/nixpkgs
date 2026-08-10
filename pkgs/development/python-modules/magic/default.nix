{
  lib,
  stdenv,
  buildPythonPackage,
  setuptools,
  pkgs,
}:

buildPythonPackage {
  pyproject = true;

  build-system = [ setuptools ];
  inherit (pkgs.file) pname version src;

  # The Python distribution is named `file-magic` and has its own version.
  dontCheckPythonMetadata = true;

  patchPhase = ''
    substituteInPlace python/magic.py --replace "find_library('magic')" "'${pkgs.file}/lib/libmagic${stdenv.hostPlatform.extensions.sharedLibrary}'"
  '';

  buildInputs = [ pkgs.file ];

  preConfigure = "cd python";

  # No test suite
  doCheck = false;

  meta = {
    description = "Python wrapper around libmagic";
    homepage = "http://www.darwinsys.com/file/";
    license = lib.licenses.lgpl2;
  };
}
