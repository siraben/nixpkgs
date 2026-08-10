{
  lib,
  buildPythonPackage,
  setuptools,
  fetchPypi,
  numpy,
  pytestCheckHook,
  twine,
}:

buildPythonPackage rec {
  pname = "nagiosplugin";
  version = "1.4.0";
  pyproject = true;

  build-system = [ setuptools ];

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-IxabBKI8StRBnvm3Zm1AH0jfMkez38P4dL4sFP0ttAE=";
  };

  nativeBuildInputs = [ twine ];

  nativeCheckInputs = [
    numpy
    pytestCheckHook
  ];

  disabledTests = [
    # Test relies on who, which does not work in the sandbox
    "test_check_users"
  ];

  pythonImportsCheck = [ "nagiosplugin" ];

  meta = {
    description = "Python class library which helps with writing Nagios (Icinga) compatible plugins";
    homepage = "https://github.com/mpounsett/nagiosplugin";
    license = lib.licenses.zpl21;
    maintainers = with lib.maintainers; [ symphorien ];
  };
}
