{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  colcon,
  colcon-argcomplete,
  colcon-bash,
  colcon-cd,
  colcon-cmake,
  colcon-defaults,
  colcon-devtools,
  colcon-library-path,
  colcon-metadata,
  colcon-notification,
  colcon-output,
  colcon-package-information,
  colcon-package-selection,
  colcon-parallel-executor,
  colcon-powershell,
  colcon-python-setup-py,
  colcon-recursive-crawl,
  colcon-ros,
  colcon-test-result,
  colcon-zsh,
}:

buildPythonPackage rec {
  pname = "colcon-common-extensions";
  version = "0.3.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "colcon";
    repo = "colcon-common-extensions";
    tag = version;
    hash = "sha256-WgE+33zJb44O7wv1+7vgRnR+Mq7UKn7FFDS6MP8sAjQ=";
  };

  build-system = [ setuptools ];

  dependencies = [
    colcon
    colcon-argcomplete
    colcon-bash
    colcon-cd
    colcon-cmake
    colcon-defaults
    colcon-devtools
    colcon-library-path
    colcon-metadata
    colcon-notification
    colcon-output
    colcon-package-information
    colcon-package-selection
    colcon-parallel-executor
    colcon-powershell
    colcon-python-setup-py
    colcon-recursive-crawl
    colcon-ros
    colcon-test-result
    colcon-zsh
  ];

  # Meta-package with no tests
  doCheck = false;

  pythonImportsCheck = [ "colcon_common_extensions" ];

  meta = {
    description = "Meta package aggregating colcon-core and common extensions";
    homepage = "https://github.com/colcon/colcon-common-extensions";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ siraben ];
  };
}
