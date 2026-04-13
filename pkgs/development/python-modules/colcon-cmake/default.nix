{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  colcon,
  colcon-library-path,
  colcon-test-result,
  packaging,
  pytestCheckHook,
  pytest-cov-stub,
}:

buildPythonPackage rec {
  pname = "colcon-cmake";
  version = "0.2.29";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "colcon";
    repo = "colcon-cmake";
    tag = version;
    hash = "sha256-v91UREVifYnwbMcM819B5CsXl8FbAH61Ydzu0vXBPX8=";
  };

  build-system = [ setuptools ];

  dependencies = [
    colcon
    colcon-library-path
    colcon-test-result
    packaging
  ];

  nativeCheckInputs = [
    pytestCheckHook
    pytest-cov-stub
  ];

  disabledTestPaths = [
    "test/test_flake8.py"
    "test/test_spell_check.py"
  ];

  pythonImportsCheck = [ "colcon_cmake" ];

  meta = {
    description = "Extension for colcon-core to support CMake projects";
    homepage = "https://github.com/colcon/colcon-cmake";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ siraben ];
  };
}
