{
  lib,
  buildPythonPackage,
  setuptools,
  numpy,
  pkgs,
  pybind11,
}:

buildPythonPackage {
  inherit (pkgs.fasttext) pname version src;

  pyproject = true;

  build-system = [
    setuptools
    pybind11
  ];

  pythonImportsCheck = [ "fasttext" ];

  propagatedBuildInputs = [ numpy ];

  preBuild = ''
    HOME=$TMPDIR
  '';

  meta = {
    description = "Python module for text classification and representation learning";
    homepage = "https://fasttext.cc/";
    license = lib.licenses.mit;
    maintainers = [ ];
  };
}
