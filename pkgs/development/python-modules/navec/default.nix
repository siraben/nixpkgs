{
  lib,
  buildPythonPackage,
  setuptools,
  fetchPypi,
  numpy,
  razdel,
  gensim,
  pytestCheckHook,
}:

buildPythonPackage rec {
  pname = "navec";
  version = "0.10.0";
  pyproject = true;

  build-system = [ setuptools ];

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-TyNHSxwnmvbGBfhOeHPofEfKWLDFOKP50w2QxgnJ/SE=";
  };

  propagatedBuildInputs = [
    numpy
    razdel
  ];
  nativeCheckInputs = [
    pytestCheckHook
    gensim
  ];
  # TODO: remove when gensim usage will be fixed in `navec`.
  disabledTests = [ "test_gensim" ];
  pythonImportsCheck = [ "navec" ];

  meta = {
    description = "Compact high quality word embeddings for Russian language";
    mainProgram = "navec-train";
    homepage = "https://github.com/natasha/navec";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ npatsakula ];
  };
}
