{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
}:

buildPythonPackage (finalAttrs: {
  pname = "playsound";
  version = "1.3.0";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "TaylorSMarks";
    repo = "playsound";
    rev = "v${finalAttrs.version}";
    sha256 = "0jbq641lmb0apq4fy6r2zyag8rdqgrz8c4wvydzrzmxrp6yx6wyd";
  };

  doCheck = false;

  pythonImportsCheck = [ "playsound" ];

  meta = {
    homepage = "https://github.com/TaylorSMarks/playsound";
    description = "Pure Python, cross platform, single function module with no dependencies for playing sounds";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    maintainers = [ ];
  };
})
