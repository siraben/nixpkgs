{
  buildPythonPackage,
  setuptools,
  usbrelay,
}:

buildPythonPackage {
  pname = "usbrelay_py";
  # The Python subproject has its own version in setup.py.
  version = "1.1";
  pyproject = true;
  inherit (usbrelay) src;

  build-system = [ setuptools ];

  preConfigure = ''
    cd usbrelay_py
  '';

  buildInputs = [ usbrelay ];

  pythonImportsCheck = [ "usbrelay_py" ];

  # The source is updated together with the parent usbrelay package.
  passthru.updateScript = null;

  inherit (usbrelay) meta;
}
