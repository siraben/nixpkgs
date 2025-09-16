{
  lib,
  buildPythonPackage,
  fetchPypi,
  pythonOlder,
  aiofiles,
  click,
  colorama,
  cryptography,
  croniter,
  gitpython,
  humanfriendly,
  pydantic,
  pyperclip,
  pyyaml,
  requests,
  shandy-sqlfmt,
  toposort,
  tornado,
  urllib3,
  wheel,
  packaging,
  setuptools,
  mypy-extensions,
}:

buildPythonPackage rec {
  pname = "tinybird-cli";
  version = "5.21.1";
  format = "wheel";

  disabled = pythonOlder "3.9";

  src = fetchPypi {
    pname = "tinybird_cli";
    inherit version;
    format = "wheel";
    dist = "py3";
    python = "py3";
    hash = "sha256-8sSpX55Pec173Dn+8ewJPLoiibfWpD2Ijv8m8bhgw3A=";
  };

  propagatedBuildInputs = [
    aiofiles
    click
    colorama
    cryptography
    croniter
    gitpython
    humanfriendly
    mypy-extensions
    pydantic
    pyperclip
    pyyaml
    requests
    shandy-sqlfmt
    toposort
    tornado
    urllib3
    wheel
    packaging
  ];

  pythonImportsCheck = [ "tinybird" ];

  meta = with lib; {
    description = "Command-line tool for Tinybird data platform";
    homepage = "https://www.tinybird.co/docs/cli";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
    mainProgram = "tb";
  };
}