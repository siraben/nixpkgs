{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pdm-backend,
  rich-toolkit,
  typer,
  uvicorn,

  # checks
  pytestCheckHook,
  rich,
}:

let
  self = buildPythonPackage rec {
    pname = "fastapi-cli";
    version = "0.0.24";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "fastapi";
      repo = "fastapi-cli";
      tag = version;
      hash = "sha256-LEo8to1mspauTMCQ5Zf6znG0ALqF5XtauPar5bqN6/Q=";
    };

    build-system = [ pdm-backend ];

    dependencies = [
      rich-toolkit
      typer
      uvicorn
    ]
    ++ uvicorn.optional-dependencies.standard;

    optional-dependencies = {
      standard = [
        uvicorn
        # FIXME package fastapi-cloud-cli
      ]
      ++ uvicorn.optional-dependencies.standard;
      standard-no-fastapi-cloud-cli = [
        uvicorn
      ]
      ++ uvicorn.optional-dependencies.standard;
    };

    doCheck = false;

    passthru.tests.pytest = self.overridePythonAttrs { doCheck = true; };

    nativeCheckInputs = [
      pytestCheckHook
      rich
    ]
    ++ optional-dependencies.standard;

    # coverage
    disabledTests = [ "test_script" ];

    pythonImportsCheck = [ "fastapi_cli" ];

    meta = {
      description = "Run and manage FastAPI apps from the command line with FastAPI CLI";
      homepage = "https://github.com/fastapi/fastapi-cli";
      changelog = "https://github.com/fastapi/fastapi-cli/releases/tag/${src.tag}";
      license = lib.licenses.mit;
      maintainers = [ ];
      # fastapi-cli no longer ships a `fastapi` executable: the entry point was
      # removed upstream in 0.0.9 and is now provided by python3Packages.fastapi
      # itself, so there is no conflict to resolve.
      priority = 10;
    };
  };
in
self
