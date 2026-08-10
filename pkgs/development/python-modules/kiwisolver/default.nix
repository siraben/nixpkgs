{
  lib,
  buildPythonPackage,
  setuptools,
  fetchPypi,
  stdenv,
  cppy,
  setuptools-scm,
}:

buildPythonPackage rec {
  pname = "kiwisolver";
  version = "1.5.0";
  pyproject = true;

  build-system = [
    cppy
    setuptools
    setuptools-scm
  ];

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-1Bk/PZ3D9veartDlY39F2YhQ6/AffKIOaUV/PolGtmo=";
  };

  env.NIX_CFLAGS_COMPILE = lib.optionalString stdenv.hostPlatform.isDarwin "-I${lib.getInclude stdenv.cc.libcxx}/include/c++/v1";

  pythonImportsCheck = [ "kiwisolver" ];

  meta = {
    description = "Implementation of the Cassowary constraint solver";
    homepage = "https://github.com/nucleic/kiwi";
    license = lib.licenses.bsd3;
    maintainers = [ ];
  };
}
