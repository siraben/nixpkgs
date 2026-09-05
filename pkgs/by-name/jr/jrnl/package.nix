{
  lib,
  fetchFromGitHub,
  python3,
  testers,
  jrnl,
}:

python3.pkgs.buildPythonApplication (finalAttrs: {
  pname = "jrnl";
  version = "4.6";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "jrnl-org";
    repo = "jrnl";
    tag = "v${finalAttrs.version}";
    hash = "sha256-g75/XY5ET09z87yogI2Jd3kRvexxBxulQdus+OjT0ck=";
  };

  build-system = with python3.pkgs; [ poetry-core ];

  dependencies = with python3.pkgs; [
    colorama
    cryptography
    keyring
    parsedatetime
    python-dateutil
    pyxdg
    ruamel-yaml
    ruamel-yaml-clib
    rich
    tzlocal
  ];

  nativeCheckInputs = with python3.pkgs; [
    pytest-bdd
    pytest-xdist
    pytest8_3CheckHook
  ];

  preCheck = ''
    export HOME=$(mktemp -d);
  '';

  pythonImportsCheck = [ "jrnl" ];

  passthru.tests.version = testers.testVersion {
    package = jrnl;
    version = "v${finalAttrs.version}";
  };

  meta = {
    description = "Command line journal application that stores your journal in a plain text file";
    homepage = "https://jrnl.sh/";
    changelog = "https://github.com/jrnl-org/jrnl/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [
      zalakain
    ];
    mainProgram = "jrnl";
  };
})
