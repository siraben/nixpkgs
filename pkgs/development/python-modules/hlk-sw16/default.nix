{
  lib,
  buildPythonPackage,
  setuptools,
  fetchFromGitHub,
}:

buildPythonPackage rec {
  pname = "hlk-sw16";
  version = "0.0.9";
  pyproject = true;

  build-system = [ setuptools ];

  src = fetchFromGitHub {
    owner = "jameshilliard";
    repo = "hlk-sw16";
    rev = version;
    sha256 = "010s85nr6xn89i8yvdagg72a97dh1v2pyfqa33v76p9p8xbgh8dz";
  };

  # no tests implemented
  doCheck = false;

  pythonImportsCheck = [ "hlk_sw16" ];

  meta = {
    description = "Python client for HLK-SW16";
    homepage = "https://github.com/jameshilliard/hlk-sw16";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ dotlambda ];
  };
}
