{
  lib,
  fetchPypi,
  buildPythonPackage,
  setuptools,
}:

buildPythonPackage rec {
  pname = "empy";
  version = "4.2";
  pyproject = true;

  build-system = [ setuptools ];
  src = fetchPypi {
    inherit pname version;
    hash = "sha256-hvFeHal0Pnmi6bLLrPGhPQt/sYNbYlTrJTyXi3Iof08=";
  };
  pythonImportsCheck = [ "em" ];
  meta = {
    homepage = "http://www.alcyone.com/software/empy/";
    description = "Templating system for Python";
    mainProgram = "em.py";
    maintainers = with lib.maintainers; [ nkalupahana ];
    license = lib.licenses.bsd3;
  };
}
