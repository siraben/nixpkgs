{
  lib,
  fetchFromGitHub,
  python3Packages,
}:

python3Packages.buildPythonApplication (finalAttrs: {
  pname = "mutmut";
  version = "3.7.0";
  pyproject = true;

  src = fetchFromGitHub {
    repo = "mutmut";
    owner = "boxed";
    tag = finalAttrs.version;
    hash = "sha256-jqJWFEYXVA6WizDO34iiyUmElGUBqsqPPyKS8AUJ7ZY=";
  };

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail "uv_build>=0.9.5,<0.10.0" uv_build
  '';

  build-system = with python3Packages; [ uv-build ];

  dependencies =
    with python3Packages;
    [
      click
      coverage
      libcst
      pytest
      setproctitle
      textual
    ]
    ++ lib.optionals (pythonOlder "3.11") [ toml ];

  nativeCheckInputs = with python3Packages; [
    inline-snapshot
    mypy
    pytest-asyncio
    pytestCheckHook
  ];

  # The snapshot is incompatible with the newer pyrefly in nixpkgs.
  disabledTests = [ "test_type_checking_pyrefly_result_snapshot" ];

  pythonImportsCheck = [ "mutmut" ];

  meta = {
    description = "Mutation testing system for Python, with a strong focus on ease of use";
    mainProgram = "mutmut";
    homepage = "https://github.com/boxed/mutmut";
    changelog = "https://github.com/boxed/mutmut/blob/${finalAttrs.version}/HISTORY.rst";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [
      l0b0
    ];
  };
})
