{
  lib,
  buildPythonPackage,
  setuptools,
  fetchPypi,
  flask,
  pytest,
}:

buildPythonPackage rec {
  pname = "flask-script";
  version = "2.0.6";
  pyproject = true;

  build-system = [ setuptools ];

  src = fetchPypi {
    pname = "Flask-Script";
    inherit version;
    hash = "sha256-ZCWWPZEFTPzBhYBxQccxSpxa1GMlkRvSTctIm9AWHGU=";
  };

  propagatedBuildInputs = [ flask ];
  nativeCheckInputs = [ pytest ];

  # No tests in archive
  doCheck = false;

  meta = {
    homepage = "https://github.com/smurfix/flask-script";
    description = "Scripting support for Flask";
    license = lib.licenses.bsd3;
    maintainers = [ ];
  };
}
