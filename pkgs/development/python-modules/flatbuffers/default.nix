{
  lib,
  buildPythonPackage,
  setuptools,
  flatbuffers,
}:

buildPythonPackage rec {
  inherit (flatbuffers) pname version src;

  pyproject = true;

  build-system = [ setuptools ];

  sourceRoot = "${src.name}/python";

  # flatbuffers needs VERSION environment variable for setting the correct
  # version, otherwise it uses the current date.
  env.VERSION = version;

  pythonImportsCheck = [ "flatbuffers" ];

  meta = flatbuffers.meta // {
    description = "Python runtime library for use with the Flatbuffers serialization format";
    maintainers = with lib.maintainers; [ wulfsta ];
    mainProgram = "flatc";
  };
}
