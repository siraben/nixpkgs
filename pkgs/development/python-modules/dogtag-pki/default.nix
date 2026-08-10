{
  lib,
  fetchPypi,
  buildPythonPackage,
  setuptools,
  cryptography,
  python-ldap,
  requests,
  six,
}:

buildPythonPackage rec {
  pname = "dogtag-pki";
  version = "11.2.1";
  pyproject = true;

  build-system = [ setuptools ];

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-rQSnQPNYr5SyeNbKoFAbnGb2X/8utrfWLa8gu93hy2w=";
  };

  buildInputs = [
    cryptography
    python-ldap
  ];
  pythonImportsCheck = [ "pki" ];
  propagatedBuildInputs = [
    requests
    six
  ];

  meta = {
    description = "Enterprise-class Certificate Authority";
    homepage = "https://github.com/dogtagpki/pki";
    license = lib.licenses.gpl2;
    maintainers = with lib.maintainers; [ s1341 ];
  };
}
