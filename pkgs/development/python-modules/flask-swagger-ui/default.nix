{
  lib,
  buildPythonPackage,
  setuptools,
  fetchPypi,
  flask,
}:

buildPythonPackage rec {
  pname = "flask-swagger-ui";
  version = "5.21.0";
  pyproject = true;

  build-system = [ setuptools ];

  src = fetchPypi {
    pname = "flask_swagger_ui";
    inherit version;
    hash = "sha256-hy0DjcEaaOrKuI9vBb48UzqjAEU+Jzd12tPgKbMeA9Q=";
  };

  doCheck = false; # there are no tests

  propagatedBuildInputs = [ flask ];

  meta = {
    homepage = "https://github.com/sveint/flask-swagger-ui";
    license = lib.licenses.mit;
    description = "Swagger UI blueprint for Flask";
    maintainers = with lib.maintainers; [ vanschelven ];
  };
}
