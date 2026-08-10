{
  lib,
  buildPythonPackage,
  setuptools,
  fetchPypi,
  pytestCheckHook,
}:

buildPythonPackage rec {
  pname = "anyascii";
  version = "0.3.3";
  pyproject = true;

  build-system = [ setuptools ];

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-yU6d2dR7PZSU7KMF/vlEfQC0vxoyr/hap0b6Psf7lcM=";
  };

  nativeCheckInputs = [ pytestCheckHook ];

  meta = {
    changelog = "https://github.com/anyascii/anyascii/blob/${version}/CHANGELOG.md";
    description = "Unicode to ASCII transliteration";
    homepage = "https://github.com/anyascii/anyascii";
    license = lib.licenses.isc;
    teams = [ lib.teams.tts ];
  };
}
