{
  lib,
  buildPythonPackage,
  fetchPypi,
  django,
  setuptools,
}:

buildPythonPackage (finalAttrs: {
  pname = "django-reversion";
  version = "6.3.0";
  pyproject = true;

  src = fetchPypi {
    pname = "django_reversion";
    inherit (finalAttrs) version;
    hash = "sha256-CqVOszRpT1Iv0jR0OXjGFNRap4XtxwphdyZ82q8G+Wc=";
  };

  build-system = [ setuptools ];

  dependencies = [ django ];

  # Tests assume the availability of a mysql/postgresql database
  doCheck = false;

  pythonImportsCheck = [ "reversion" ];

  meta = {
    description = "Extension to the Django web framework that provides comprehensive version control facilities";
    homepage = "https://github.com/etianen/django-reversion";
    changelog = "https://github.com/etianen/django-reversion/blob/v${finalAttrs.version}/CHANGELOG.rst";
    license = lib.licenses.bsd3;
    maintainers = [ ];
  };
})
