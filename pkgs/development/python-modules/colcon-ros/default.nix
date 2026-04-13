{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  catkin-pkg,
  colcon,
  colcon-cmake,
  colcon-pkg-config,
  colcon-python-setup-py,
  colcon-recursive-crawl,
  pytestCheckHook,
  pytest-cov-stub,
}:

buildPythonPackage rec {
  pname = "colcon-ros";
  version = "0.5.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "colcon";
    repo = "colcon-ros";
    tag = version;
    hash = "sha256-BsGCgFGxOIAGTP4A8bulakMoeUj+Ki6sPIpTQ4L7LSo=";
  };

  build-system = [ setuptools ];

  dependencies = [
    catkin-pkg
    colcon
    colcon-cmake
    colcon-pkg-config
    colcon-python-setup-py
    colcon-recursive-crawl
  ];

  nativeCheckInputs = [
    pytestCheckHook
    pytest-cov-stub
  ];

  disabledTestPaths = [
    "test/test_flake8.py"
    "test/test_spell_check.py"
  ];

  pythonImportsCheck = [ "colcon_ros" ];

  meta = {
    description = "Extension for colcon-core to support ROS packages";
    homepage = "https://github.com/colcon/colcon-ros";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ siraben ];
  };
}
