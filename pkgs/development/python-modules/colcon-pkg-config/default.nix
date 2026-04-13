{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  colcon,
  pytestCheckHook,
  pytest-cov-stub,
}:

buildPythonPackage rec {
  pname = "colcon-pkg-config";
  version = "0.1.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "colcon";
    repo = "colcon-pkg-config";
    tag = version;
    hash = "sha256-CCtRZ4hBfF+StTsr9tV+mGCqGhHk7GQ0JWIV4ZaCtN8=";
  };

  build-system = [ setuptools ];

  dependencies = [ colcon ];

  nativeCheckInputs = [
    pytestCheckHook
    pytest-cov-stub
  ];

  disabledTestPaths = [
    "test/test_flake8.py"
    "test/test_spell_check.py"
  ];

  pythonImportsCheck = [ "colcon_pkg_config" ];

  meta = {
    description = "Extension for colcon-core to provide pkg-config path environment variable";
    homepage = "https://github.com/colcon/colcon-pkg-config";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ siraben ];
  };
}
