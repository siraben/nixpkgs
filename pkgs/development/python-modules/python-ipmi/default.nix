{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pytestCheckHook,
  setuptools,
}:

buildPythonPackage (finalAttrs: {
  pname = "python-ipmi";
  version = "0.5.8";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "kontron";
    repo = "python-ipmi";
    tag = finalAttrs.version;
    hash = "sha256-9xPnLNyHKvVebRM/mIoEVzhT2EwmgJxCTztLSZrnXVc=";
  };

  postPatch = ''
    substituteInPlace setup.py \
      --replace-fail "version=version," "version='${finalAttrs.version}',"
  '';

  build-system = [ setuptools ];

  nativeCheckInputs = [ pytestCheckHook ];

  pythonImportsCheck = [ "pyipmi" ];

  meta = {
    description = "Python IPMI Library";
    homepage = "https://github.com/kontron/python-ipmi";
    license = lib.licenses.lgpl2Plus;
    maintainers = with lib.maintainers; [ fab ];
    mainProgram = "ipmitool.py";
  };
})
