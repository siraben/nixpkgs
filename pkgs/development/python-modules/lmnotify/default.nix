{
  lib,
  buildPythonPackage,
  setuptools,
  fetchPypi,
  oauthlib,
  requests,
  requests-oauthlib,
}:

buildPythonPackage rec {
  pname = "lmnotify";
  version = "0.0.6";
  pyproject = true;

  build-system = [ setuptools ];

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-cCP7BU2f7QJe9gAI298cvkp3OGijvBv8G1RN7qfZ5PE=";
  };

  propagatedBuildInputs = [
    oauthlib
    requests
    requests-oauthlib
  ];

  # Module has no tests
  doCheck = false;

  pythonImportsCheck = [ "lmnotify" ];

  meta = {
    description = "Python package for sending notifications to LaMetric Time";
    homepage = "https://github.com/keans/lmnotify";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ rhoriguchi ];
  };
}
