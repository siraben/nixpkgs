{
  lib,
  buildPythonPackage,
  setuptools,
  fetchFromGitHub,
  requests,
}:

buildPythonPackage rec {
  pname = "mcuuid";
  version = "1.1.0";
  pyproject = true;

  build-system = [ setuptools ];

  src = fetchFromGitHub {
    owner = "clerie";
    repo = "mcuuid";
    tag = version;
    hash = "sha256-YwM7CdZVXpUXKXUzFL3AtoDhekLDIvZ/q8taLsHihNk=";
  };

  propagatedBuildInputs = [ requests ];

  # upstream code does not provide tests
  doCheck = false;

  pythonImportsCheck = [ "mcuuid" ];

  meta = {
    description = "Getting Minecraft player information from Mojang API";
    homepage = "https://github.com/clerie/mcuuid";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ clerie ];
  };
}
