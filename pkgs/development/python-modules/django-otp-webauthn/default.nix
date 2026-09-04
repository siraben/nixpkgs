{
  lib,
  buildPythonPackage,
  fetchPypi,
  hatchling,
  django,
  django-otp,
  djangorestframework,
  webauthn,
}:

buildPythonPackage (finalAttrs: {
  pname = "django-otp-webauthn";
  version = "0.8.0";
  pyproject = true;

  src = fetchPypi {
    inherit (finalAttrs) version;
    pname = "django_otp_webauthn";
    hash = "sha256-GMkKL+U7CPfw3WaSlsnoi0VmEPF/wbb86phfl01NM6I=";
  };

  build-system = [ hatchling ];

  dependencies = [
    django
    django-otp
    djangorestframework
    webauthn
  ];

  # Tests are on the roadmap, but not yet implemented

  pythonImportsCheck = [ "django_otp_webauthn" ];

  meta = {
    description = "Passkey support for Django";
    homepage = "https://github.com/Stormbase/django-otp-webauthn";
    changelog = "https://github.com/Stormbase/django-otp-webauthn/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ erictapen ];
  };

})
