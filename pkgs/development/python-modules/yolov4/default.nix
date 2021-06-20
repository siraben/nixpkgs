{ lib, fetchFromGitHub, buildPythonPackage, pytest, opencv3, tensorflow }:

buildPythonPackage rec {
  pname = "yolov4";
  version = "3.2.0";

  src = fetchFromGitHub {
    owner = "hhk7734";
    repo = "tensorflow-yolov4";
    rev = "v${version}";
    sha256 = "sha256-2pR0wIGaMOEz5YDGQGMc0zkcqH1HSm3kZJUliv9SXRQ=";
  };

  buildInputs = [ pytest ];

  propagatedBuildInputs = [ opencv3 tensorflow ];

  doCheck = false;

  meta = with lib; {
    description = "Deep learning library featuring a higher-level API for TensorFlow";
    homepage    = "https://github.com/tflearn/tflearn";
    license     = licenses.mit;
  };
}
