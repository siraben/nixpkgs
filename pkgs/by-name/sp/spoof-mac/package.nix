{
  lib,
  python3Packages,
  fetchFromGitHub,
}:

python3Packages.buildPythonPackage {
  pname = "spoof-mac";
  version = "2.1.1-unstable-2018-01-27";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "feross";
    repo = "SpoofMAC";
    rev = "2cfc796150ef48009e9b765fe733e37d82c901e0";
    hash = "sha256-Qiu0URjUyx8QDVQQUFGxPax0J80e2m4+bPJeqFoKxX8=";
  };

  build-system = [ python3Packages.setuptools ];

  dependencies = [ python3Packages.docopt ];

  # No tests
  doCheck = false;

  pythonImportsCheck = [ "spoofmac" ];

  meta = {
    description = "Change your MAC address for debugging purposes";
    homepage = "https://github.com/feross/SpoofMAC";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ siraben ];
    mainProgram = "spoof-mac";
    platforms = lib.platforms.unix;
  };
}
