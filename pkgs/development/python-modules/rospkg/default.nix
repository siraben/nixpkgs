{
  lib,
  buildPythonPackage,
  catkin-pkg,
  distro,
  distutils,
  fetchFromGitHub,
  pytestCheckHook,
  pyyaml,
  setuptools,
}:

buildPythonPackage (finalAttrs: {
  pname = "rospkg";
  version = "1.6.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "ros-infrastructure";
    repo = "rospkg";
    tag = finalAttrs.version;
    hash = "sha256-YRBmL+aXQ/0rxivERja9ng+GqL8NQGmNYhKjMY7+6nc=";
  };

  build-system = [ setuptools ];

  setupHook = ./setup-hook.sh;

  dependencies = [
    catkin-pkg
    distro
    distutils
    pyyaml
  ];

  nativeCheckInputs = [
    pytestCheckHook
  ];

  pythonImportsCheck = [ "rospkg" ];

  meta = {
    description = "ROS package library for Python";
    homepage = "http://wiki.ros.org/rospkg";
    changelog = "https://github.com/ros-infrastructure/rospkg/blob/${finalAttrs.version}/CHANGELOG.rst";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ guelakais ];
  };
})
