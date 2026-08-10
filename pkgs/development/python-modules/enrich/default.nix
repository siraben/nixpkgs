{
  lib,
  buildPythonPackage,
  setuptools,
  fetchPypi,
  pytestCheckHook,
  setuptools-scm,
  rich,
  pytest-mock,
}:

buildPythonPackage rec {
  pname = "enrich";
  version = "1.2.7";
  pyproject = true;

  build-system = [
    setuptools
    setuptools-scm
  ];

  src = fetchPypi {
    inherit pname version;
    sha256 = "0a2ab0d2931dff8947012602d1234d2a3ee002d9a355b5d70be6bf5466008893";
  };

  postPatch = ''
    sed -i \
      -e '/"pip >=/d' \
      -e '/setuptools_scm_git_archive/d' \
      -e '/"wheel >=/d' \
      pyproject.toml
  '';

  propagatedBuildInputs = [ rich ];

  nativeCheckInputs = [
    pytestCheckHook
    pytest-mock
  ];

  disabledTests = [
    # console output order is racy
    "test_rich_console_ex"
  ];

  pythonImportsCheck = [ "enrich" ];

  meta = {
    description = "Enrich adds few missing features to the wonderful rich library";
    homepage = "https://github.com/pycontribs/enrich";
    license = lib.licenses.mit;
    maintainers = [ ];
  };
}
