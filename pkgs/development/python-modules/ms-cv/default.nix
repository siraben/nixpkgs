{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pytestCheckHook,
}:

buildPythonPackage (finalAttrs: {
  pname = "ms-cv";
  version = "0.1.1";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "OpenXbox";
    repo = "ms_cv";
    rev = "v${finalAttrs.version}";
    sha256 = "0pkna0kvmq1cp4rx3dnzxsvvlxxngryp77k42wkyw2phv19a2mjd";
  };

  postPatch = ''
    substituteInPlace setup.py \
      --replace "pytest-runner" ""
  '';

  nativeCheckInputs = [ pytestCheckHook ];

  meta = {
    description = "Correlation vector implementation in python";
    homepage = "https://github.com/OpenXbox/ms_cv";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ dotlambda ];
  };
})
