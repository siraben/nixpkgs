{
  lib,
  buildPythonPackage,
  fetchPypi,
  python,
  pythonAtLeast,
  zc-buildout,
  zope-testrunner,
}:

buildPythonPackage (finalAttrs: {
  pname = "z3c-checkversions";
  version = "3.0";
  format = "setuptools";

  # distutils usage
  disabled = pythonAtLeast "3.12";

  src = fetchPypi {
    inherit (finalAttrs) version;
    pname = "z3c.checkversions";
    hash = "sha256-VMGSlocgEddBrUT0A4ihtCdhSbirWYe9FmQ0QyOGOEs=";
  };

  propagatedBuildInputs = [ zc-buildout ];

  nativeCheckInputs = [ zope-testrunner ];

  checkPhase = ''
    ${python.interpreter} -m zope.testrunner --test-path=src []
  '';

  meta = {
    homepage = "https://github.com/zopefoundation/z3c.checkversions";
    changelog = "https://github.com/zopefoundation/z3c.checkversions/blob/${finalAttrs.version}/CHANGES.rst";
    description = "Find newer package versions on PyPI";
    mainProgram = "checkversions";
    license = lib.licenses.zpl21;
  };
})
