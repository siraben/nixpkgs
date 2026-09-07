{
  lib,
  buildPythonPackage,
  fetchPypi,

  # dependencies
  aiohttp,
  alembic,
  cryptography,
  docker,
  flask,
  flask-cors,
  graphene,
  gunicorn,
  huey,
  matplotlib,
  mlflow-skinny,
  mlflow-tracing,
  numpy,
  pandas,
  pyarrow,
  scikit-learn,
  scipy,
  skops,
  sqlalchemy,
}:

buildPythonPackage (finalAttrs: {
  pname = "mlflow";
  version = "3.15.2";
  format = "wheel";
  __structuredAttrs = true;

  # The server and job runner start Python subprocesses which import mlflow and its dependencies.
  propagatePythonPath = true;

  # We build from the PyPI wheel rather than fetchFromGitHub, because the mlflow-server
  # JS UI is absent from GitHub but provided in the wheel.
  src = fetchPypi {
    pname = "mlflow";
    inherit (finalAttrs) version;
    format = "wheel";
    dist = "py3";
    python = "py3";
    hash = "sha256-eqWWZDUaqm9jR4zzwml3wYXbpg0ovKi5pRJb46K0MRw=";
  };

  pythonRelaxDeps = [
    "cryptography"

    # 3.14.0 dependency check fails with pandas >= 3.0. But the code changes required are minimal
    # (strings are now `str` instead of `numpy.object`.)
    "pandas"
  ];

  dependencies = [
    aiohttp
    alembic
    cryptography
    docker
    flask
    flask-cors
    graphene
    gunicorn
    huey
    matplotlib
    mlflow-skinny
    mlflow-tracing
    numpy
    pandas
    pyarrow
    scikit-learn
    scipy
    skops
    sqlalchemy
  ];

  pythonImportsCheck = [ "mlflow" ];

  # I (@GaetanLepage) gave up at enabling tests:
  # - They require a lot of dependencies (some unpackaged);
  # - Many errors occur at collection time;
  # - Most (all ?) tests require internet access anyway.
  doCheck = false;

  meta = {
    description = "Open source platform for the machine learning lifecycle";
    mainProgram = "mlflow";
    homepage = "https://github.com/mlflow/mlflow";
    changelog = "https://github.com/mlflow/mlflow/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.asl20;
    # Build from wheel which contains pure Python and pre-built JS bundle.
    sourceProvenance = with lib.sourceTypes; [
      binaryBytecode
    ];
    maintainers = with lib.maintainers; [
      GaetanLepage
      gquetel
    ];
  };
})
