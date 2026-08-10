{
  lib,
  buildPythonPackage,
  setuptools,
  fetchPypi,
  pytools,
  numpy,
}:

buildPythonPackage rec {
  pname = "genpy";
  version = "2022.1";
  pyproject = true;

  build-system = [ setuptools ];

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-FGZbQlUgbJjnuiDaKS/vVlraMVmFF1cAQk7S3aPWXx4=";
  };

  propagatedBuildInputs = [
    pytools
    numpy
  ];

  meta = {
    description = "C/C++ source generation from an AST";
    homepage = "https://github.com/inducer/genpy";
    license = lib.licenses.mit;
    maintainers = [ ];
  };
}
