{
  lib,
  buildPythonPackage,
  setuptools,
  fetchPypi,
}:

buildPythonPackage rec {
  pname = "flashtext";
  version = "2.7";
  pyproject = true;

  build-system = [ setuptools ];

  src = fetchPypi {
    inherit pname version;
    sha256 = "1kq5idfp9skqkjdcld40igxn2yqjly8jpmxawkp0skwxw29jpgm1";
  };

  # json files that tests look for don't exist in the pypi dist
  doCheck = false;

  meta = {
    homepage = "https://github.com/vi3k6i5/flashtext";
    description = "Python package to replace keywords in sentences or extract keywords from sentences";
    maintainers = with lib.maintainers; [ aanderse ];
    license = lib.licenses.mit;
  };
}
