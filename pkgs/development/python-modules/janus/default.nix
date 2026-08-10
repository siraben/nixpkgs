{
  lib,
  buildPythonPackage,
  setuptools,
  fetchPypi,
  pytestCheckHook,
  pytest-asyncio,
  pytest-benchmark,
  pytest-cov-stub,
  typing-extensions,
}:

buildPythonPackage rec {
  pname = "janus";
  version = "2.0.0";
  pyproject = true;

  build-system = [ setuptools ];

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-CXDzjg5yVABJbINKNopn7lUdw7WtCiV+Ey9bRvLnd3A=";
  };

  propagatedBuildInputs = [ typing-extensions ];

  nativeCheckInputs = [
    pytest-asyncio
    pytest-benchmark
    pytest-cov-stub
    pytestCheckHook
  ];

  pytestFlags = [ "--benchmark-disable" ];

  meta = {
    description = "Mixed sync-async queue";
    homepage = "https://github.com/aio-libs/janus";
    license = lib.licenses.asl20;
    maintainers = [ lib.maintainers.simonchatts ];
  };
}
