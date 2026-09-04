{
  lib,
  aiohttp,
  buildPythonPackage,
  fetchFromGitHub,
}:

buildPythonPackage (finalAttrs: {
  pname = "pyvolumio";
  version = "0.1.5";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "OnFreund";
    repo = "PyVolumio";
    rev = "v${finalAttrs.version}";
    sha256 = "1nyvflap39cwq1cm9wwl9idvfmz1ixsl80f1dnskx22fk0lmvj4h";
  };

  propagatedBuildInputs = [ aiohttp ];

  # Project has no tests
  doCheck = false;

  pythonImportsCheck = [ "pyvolumio" ];

  meta = {
    description = "Python module to control Volumio";
    homepage = "https://github.com/OnFreund/PyVolumio";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ fab ];
  };
})
