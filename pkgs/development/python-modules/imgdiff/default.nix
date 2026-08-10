{
  lib,
  buildPythonPackage,
  setuptools,
  fetchFromGitHub,
  pillow,
  mock,
  unittestCheckHook,
}:

buildPythonPackage rec {
  pname = "imgdiff";
  version = "1.8.0";
  pyproject = true;

  build-system = [ setuptools ];

  src = fetchFromGitHub {
    owner = "mgedmin";
    repo = "imgdiff";
    rev = version;
    hash = "sha256-Ko2m6rLKUmRveHIeIylGWFXyDwlf3E7mkNHKxk7HBbA=";
  };

  propagatedBuildInputs = [ pillow ];

  pythonImportsCheck = [ "imgdiff" ];

  nativeCheckInputs = [
    mock
    unittestCheckHook
  ];

  meta = {
    description = "Compare two images side-by-side";
    mainProgram = "imgdiff";
    homepage = "https://github.com/mgedmin/imgdiff";
    changelog = "https://github.com/mgedmin/imgdiff/blob/${src.rev}/CHANGES.rst";
    license = lib.licenses.mit;
    maintainers = [ ];
  };
}
