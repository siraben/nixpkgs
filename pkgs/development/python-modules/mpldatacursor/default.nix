{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  matplotlib,
}:

buildPythonPackage (finalAttrs: {
  pname = "mpldatacursor";
  version = "0.7.1";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "joferkington";
    repo = "mpldatacursor";
    rev = "v${finalAttrs.version}";
    sha256 = "0i1lwl6x6hgjq4xwsc138i4v5895lmnpfqwpzpnj5mlck6fy6rda";
  };

  propagatedBuildInputs = [ matplotlib ];

  # No tests included in archive
  doCheck = false;

  pythonImportsCheck = [ "mpldatacursor" ];

  meta = {
    homepage = "https://github.com/joferkington/mpldatacursor";
    description = "Interactive data cursors for matplotlib";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ bzizou ];
  };
})
