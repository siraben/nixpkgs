{ lib, fetchPypi, buildPythonPackage, pytest, opencv3, tensorflow }:

buildPythonPackage rec {
  pname = "yolov4";
  version = "3.2.0";

  src = fetchPypi {
    pname = "tensorflow-yolov4";
    version = "v${version}";
    sha256 = "818aa57667603810415dc203ba3f75f1541e931a8dc30b6e8b21563541a70388";
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
