{
  lib,
  buildPythonPackage,
  setuptools,
  fetchFromGitHub,
  django,
  static3,
}:

buildPythonPackage rec {
  pname = "dj-static";
  version = "0.0.6";
  pyproject = true;

  build-system = [ setuptools ];

  src = fetchFromGitHub {
    owner = "heroku-python";
    repo = "dj-static";
    rev = "v${version}";
    hash = "sha256-B6TydlezbDkmfFgJjdFniZIYo/JjzPvFj43co+HYCdc=";
  };

  buildInputs = [ django ];

  propagatedBuildInputs = [ static3 ];

  pythonImportsCheck = [ "dj_static" ];

  doCheck = false;

  meta = {
    description = "Serve production static files with Django";
    homepage = "https://github.com/heroku-python/dj-static";
    license = lib.licenses.bsd2;
    maintainers = with lib.maintainers; [ hexa ];
  };
}
