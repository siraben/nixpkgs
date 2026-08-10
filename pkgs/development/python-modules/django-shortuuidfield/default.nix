{
  lib,
  buildPythonPackage,
  setuptools,
  django,
  fetchPypi,
  shortuuid,
  six,
}:

buildPythonPackage rec {
  pname = "django-shortuuidfield";
  version = "0.1.3";
  pyproject = true;

  build-system = [ setuptools ];

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-opLA/lU4q+lHsTHiuRTt2axEr8xqQOrscUSOYjGj7wA=";
  };

  propagatedBuildInputs = [
    django
    shortuuid
    six
  ];

  # no tests
  doCheck = false;

  pythonImportsCheck = [ "shortuuidfield" ];

  meta = {
    description = "Short UUIDField for Django. Good for use in urls & file names";
    homepage = "https://github.com/benrobster/django-shortuuidfield";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ derdennisop ];
  };
}
