{
  lib,
  buildPythonPackage,
  poetry-core,
  fetchPypi,
  django,
  six,
  pycrypto,
}:

buildPythonPackage rec {
  pname = "libthumbor";
  version = "2.0.2";
  pyproject = true;

  build-system = [ poetry-core ];

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-1PsiFZrTDVQqy8A3nkaM5LdPiBoriRgHkklTOiczN+g=";
  };

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail 'requires = ["poetry>=0.12"]' 'requires = ["poetry-core"]' \
      --replace-fail 'build-backend = "poetry.masonry.api"' 'build-backend = "poetry.core.masonry.api"'
  '';

  buildInputs = [ django ];

  propagatedBuildInputs = [
    six
    pycrypto
  ];

  doCheck = false;

  pythonImportsCheck = [ "libthumbor" ];

  meta = {
    description = "Python extension to thumbor";
    homepage = "https://github.com/heynemann/libthumbor";
    license = lib.licenses.mit;
    maintainers = [ ];
  };
}
