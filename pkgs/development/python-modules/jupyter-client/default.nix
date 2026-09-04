{
  lib,
  buildPythonPackage,
  fetchPypi,
  jupyter-core,
  hatchling,
  python-dateutil,
  pyzmq,
  tornado,
  traitlets,
}:

buildPythonPackage (finalAttrs: {
  pname = "jupyter-client";
  version = "8.8.0";
  pyproject = true;

  src = fetchPypi {
    pname = "jupyter_client";
    inherit (finalAttrs) version;
    hash = "sha256-1VaBFBmk8tlshprzToVOPwWbfMLW0Bqc2chcJnaRvj4=";
  };

  build-system = [ hatchling ];

  dependencies = [
    jupyter-core
    python-dateutil
    pyzmq
    tornado
    traitlets
  ];

  pythonImportsCheck = [ "jupyter_client" ];

  # Circular dependency with ipykernel
  doCheck = false;

  meta = {
    description = "Jupyter protocol implementation and client libraries";
    homepage = "https://github.com/jupyter/jupyter_client";
    changelog = "https://github.com/jupyter/jupyter_client/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.bsd3;
    teams = [ lib.teams.jupyter ];
  };
})
