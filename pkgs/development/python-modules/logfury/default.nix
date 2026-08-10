{
  lib,
  buildPythonPackage,
  setuptools,
  fetchPypi,
  setuptools-scm,
  pytestCheckHook,
  testfixtures,
}:

buildPythonPackage rec {
  pname = "logfury";
  version = "1.0.1";
  pyproject = true;

  build-system = [
    setuptools
    setuptools-scm
  ];

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-EwpdrOq5rVNJJCUt33BIKqLJZmKzo4JafTCYHQO3aiY=";
  };

  nativeCheckInputs = [
    pytestCheckHook
    testfixtures
  ];

  postPatch = ''
    substituteInPlace setup.py \
      --replace "'setuptools_scm<6.0'" "'setuptools_scm'"
  '';

  pythonImportsCheck = [ "logfury" ];

  meta = {
    description = "Python module that allows for responsible, low-boilerplate logging of method calls";
    homepage = "https://github.com/ppolewicz/logfury";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ jwiegley ];
  };
}
