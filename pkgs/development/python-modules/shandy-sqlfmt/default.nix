{
  lib,
  buildPythonPackage,
  fetchPypi,
  pythonOlder,
  poetry-core,
  click,
  platformdirs,
  pythonRelaxDepsHook,
  tomli,
  tqdm,
}:

buildPythonPackage rec {
  pname = "shandy-sqlfmt";
  version = "0.11.1";
  pyproject = true;

  disabled = pythonOlder "3.8";

  src = fetchPypi {
    pname = "shandy-sqlfmt";
    inherit version;
    hash = "sha256-L3vgUJtQXlmAD5TaF/X8zuTOKCQV/Fs+lkqkW1hiRwg=";
  };

  build-system = [
    poetry-core
  ];

  nativeBuildInputs = [
    pythonRelaxDepsHook
  ];

  dependencies = [
    click
    platformdirs
    tomli
    tqdm
  ];

  pythonRelaxDeps = [
    "platformdirs"
  ];

  pythonImportsCheck = [ "sqlfmt" ];

  meta = with lib; {
    description = "SQL formatter for dbt SQL files";
    homepage = "https://github.com/tconbeer/sqlfmt";
    license = licenses.asl20;
    maintainers = with maintainers; [ ];
  };
}