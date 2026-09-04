{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  pytestCheckHook,
}:

buildPythonPackage (finalAttrs: {
  pname = "pyspellchecker";
  version = "0.9.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "barrust";
    repo = "pyspellchecker";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Ui1IPqvVqf7scMg+B1KmI5jWrHSsuaW6sCoWeiF2oMI=";
  };

  nativeBuildInputs = [ setuptools ];

  nativeCheckInputs = [ pytestCheckHook ];

  meta = {
    description = "Pure python spell checking";
    homepage = "https://github.com/barrust/pyspellchecker";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ zendo ];
  };
})
