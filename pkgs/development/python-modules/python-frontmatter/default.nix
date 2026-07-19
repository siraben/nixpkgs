{
  lib,
  fetchFromGitHub,
  buildPythonPackage,
  uv-build,
  pyyaml,
  pytest,
  pyaml,
}:

buildPythonPackage rec {
  pname = "python-frontmatter";
  version = "1.3.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "eyeseast";
    repo = "python-frontmatter";
    tag = "v${version}";
    sha256 = "sha256-b/ruWPPiKvDzMjcVhxiBtnAaMNWnWvy1v8GZxGeibyY=";
  };

  build-system = [ uv-build ];

  dependencies = [ pyyaml ];

  # tries to import test.test, which conflicts with module
  # exported by python interpreter
  doCheck = false;
  nativeCheckInputs = [
    pyaml
    pytest
  ];

  pythonImportsCheck = [ "frontmatter" ];

  meta = {
    homepage = "https://github.com/eyeseast/python-frontmatter";
    description = "Parse and manage posts with YAML (or other) frontmatter";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ siraben ];
    platforms = lib.platforms.unix;
  };
}
