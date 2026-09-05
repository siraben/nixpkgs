{
  buildPythonPackage,
  fetchPypi,
  lib,
  setuptools,
}:

buildPythonPackage (finalAttrs: {
  pname = "lhafile";
  version = "0.3.1";
  pyproject = true;

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-pmoJHmGvVpOEhE7XS/dhecV15dKLyIv5v1R2ozl9B30=";
  };

  build-system = [ setuptools ];

  pythonImportsCheck = [ "lhafile" ];

  meta = {
    description = "LHA archive support for Python";
    homepage = "https://github.com/FrodeSolheim/python-lhafile";
    license = lib.licenses.bsd3;
    maintainers = [ ];
  };
})
