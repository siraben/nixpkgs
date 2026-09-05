{
  lib,
  buildPythonPackage,
  fetchPypi,
  python,
  setuptools,
}:

buildPythonPackage (finalAttrs: {
  pname = "gherkin-official";
  version = "29.0.0";
  pyproject = true;

  src = fetchPypi {
    pname = "gherkin_official";
    inherit (finalAttrs) version;
    hash = "sha256-2+oyVhFY8CKA11edF5sBkWDQcs4IMZdiXi+Apndrues=";
  };

  postPatch = ''
    cat > bin/gherkin <<'PY'
    #!${python.interpreter}
    import runpy
    runpy.run_module("gherkin", run_name="__main__")
    PY
  '';

  build-system = [ setuptools ];

  # Tests are not included in the source distribution.
  doCheck = false;

  pythonImportsCheck = [ "gherkin" ];

  meta = {
    description = "Gherkin parser maintained by the Cucumber team";
    homepage = "https://github.com/cucumber/gherkin";
    license = lib.licenses.mit;
    mainProgram = "gherkin";
  };
})
