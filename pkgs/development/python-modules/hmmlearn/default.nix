{
  lib,
  fetchPypi,
  buildPythonPackage,
  setuptools,
  numpy,
  scikit-learn,
  pybind11,
  setuptools-scm,
  cython,
  pytestCheckHook,
}:

buildPythonPackage rec {
  pname = "hmmlearn";
  version = "0.3.3";
  pyproject = true;

  build-system = [
    setuptools
    setuptools-scm
    pybind11
  ];

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-HTxdxMUlfgwjjcH+U4dwC4y5h+q4CO2z4Mc4KfHMROw=";
  };

  nativeBuildInputs = [ cython ];

  propagatedBuildInputs = [
    numpy
    scikit-learn
  ];

  nativeCheckInputs = [ pytestCheckHook ];

  pythonImportsCheck = [ "hmmlearn" ];

  pytestFlags = [
    "--pyargs"
    "hmmlearn"
  ];

  meta = {
    description = "Hidden Markov Models in Python with scikit-learn like API";
    homepage = "https://github.com/hmmlearn/hmmlearn";
    license = lib.licenses.bsd3;
    maintainers = [ ];
  };
}
