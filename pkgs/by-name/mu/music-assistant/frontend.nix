{
  lib,
  buildPythonPackage,
  fetchPypi,
  music-assistant,
  setuptools,
}:

buildPythonPackage (finalAttrs: {
  pname = "music-assistant-frontend";
  version = "2.17.186.post3";
  pyproject = true;

  src = fetchPypi {
    pname = "music_assistant_frontend";
    inherit (finalAttrs) version;
    hash = "sha256-a+Z2HuUuvkZQragrRP6vlofk6x/xJHWmnZPBa2BHpso=";
  };

  build-system = [ setuptools ];

  doCheck = false;

  pythonImportsCheck = [ "music_assistant_frontend" ];

  meta = {
    changelog = "https://github.com/music-assistant/frontend/releases/tag/${finalAttrs.version}";
    description = "Music Assistant frontend";
    homepage = "https://github.com/music-assistant/frontend";
    license = lib.licenses.asl20;
    inherit (music-assistant.meta) maintainers;
  };
})
