{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
}:

buildPythonPackage (finalAttrs: {
  pname = "configargparse";
  version = "1.5.3";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "bw2";
    repo = "ConfigArgParse";
    rev = "v${finalAttrs.version}";
    sha256 = "1dsai4bilkp2biy9swfdx2z0k4akw4lpvx12flmk00r80hzgbglz";
  };

  doCheck = false;

  pythonImportsCheck = [ "configargparse" ];

  meta = {
    description = "Drop-in replacement for argparse";
    homepage = "https://github.com/bw2/ConfigArgParse";
    license = lib.licenses.mit;
  };
})
