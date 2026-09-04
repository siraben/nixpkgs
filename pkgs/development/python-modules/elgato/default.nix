{
  lib,
  aiohttp,
  aresponses,
  buildPythonPackage,
  fetchFromGitHub,
  mashumaro,
  orjson,
  poetry-core,
  pytest-asyncio,
  pytest-cov-stub,
  pytestCheckHook,
  yarl,
}:

buildPythonPackage (finalAttrs: {
  pname = "elgato";
  version = "5.1.2";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "frenck";
    repo = "python-elgato";
    tag = "v${finalAttrs.version}";
    hash = "sha256-NAU4tr0oaAPPrOUZYl9WoGOM68MlrBqGewHBIiIv2XY=";
  };

  postPatch = ''
    # Upstream doesn't set a version for the pyproject.toml
    substituteInPlace pyproject.toml \
      --replace "0.0.0" "${finalAttrs.version}"
  '';

  build-system = [ poetry-core ];

  dependencies = [
    aiohttp
    mashumaro
    orjson
    yarl
  ];

  nativeCheckInputs = [
    aresponses
    pytest-asyncio
    pytest-cov-stub
    pytestCheckHook
  ];

  pythonImportsCheck = [ "elgato" ];

  meta = {
    description = "Python client for Elgato Key Lights";
    homepage = "https://github.com/frenck/python-elgato";
    changelog = "https://github.com/frenck/python-elgato/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ fab ];
  };
})
