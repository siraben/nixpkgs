{
  lib,
  buildPythonPackage,
  setuptools,
  fetchFromGitHub,
  numpy,
  pytestCheckHook,
  setuptools-scm,
}:

buildPythonPackage rec {
  pname = "emcee";
  version = "3.1.6";
  pyproject = true;

  build-system = [
    setuptools
    setuptools-scm
  ];

  src = fetchFromGitHub {
    owner = "dfm";
    repo = "emcee";
    tag = "v${version}";
    hash = "sha256-JVZK3kvDwWENho0OxZ9OxATcm3XpGmX+e7alPclRsHY=";
  };

  propagatedBuildInputs = [ numpy ];

  nativeCheckInputs = [ pytestCheckHook ];

  pythonImportsCheck = [ "emcee" ];

  meta = {
    description = "Kick ass affine-invariant ensemble MCMC sampling";
    homepage = "https://emcee.readthedocs.io/";
    changelog = "https://github.com/dfm/emcee/releases/tag/v${version}";
    license = lib.licenses.mit;
    maintainers = [ ];
  };
}
