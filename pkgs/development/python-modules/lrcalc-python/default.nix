{
  lib,
  fetchPypi,
  buildPythonPackage,
  setuptools,
  cython,
  pkg-config,
  lrcalc,
}:

buildPythonPackage rec {
  pname = "lrcalc-python";
  version = "2.1";
  pyproject = true;

  build-system = [
    cython
    setuptools
  ];

  # The distribution is named `lrcalc`.
  dontCheckPythonMetadata = true;

  src = fetchPypi {
    inherit version;
    pname = "lrcalc";
    sha256 = "e3a0509aeda487b412b391a52e817ca36b5c063a8305e09fd54d53259dd6aaa9";
  };

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [ lrcalc ];

  pythonImportsCheck = [ "lrcalc" ];

  meta = {
    description = "Littlewood-Richardson Calculator bindings";
    homepage = "https://sites.math.rutgers.edu/~asbuch/lrcalc/";
    teams = [ lib.teams.sage ];
    license = lib.licenses.gpl3;
  };
}
