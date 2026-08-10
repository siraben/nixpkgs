{
  lib,
  buildPythonPackage,
  setuptools,
  fetchPypi,
}:

buildPythonPackage rec {
  pname = "future-typing";
  version = "0.4.1";
  pyproject = true;

  build-system = [ setuptools ];

  src = fetchPypi {
    pname = "future_typing";
    inherit version;
    sha256 = "65fdc5034a95db212790fee5e977fb0a2df8deb60dccf3bac17d6d2b1a9bbacd";
  };

  doCheck = false; # No tests in pypi source. Did not get tests from GitHub source to work.

  pythonImportsCheck = [ "future_typing" ];

  meta = {
    description = "Use generic type hints and new union syntax `|` with python 3.6+";
    mainProgram = "future_typing";
    homepage = "https://github.com/PrettyWood/future-typing";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ kfollesdal ];
  };
}
