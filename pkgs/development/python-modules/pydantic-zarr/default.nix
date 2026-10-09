{
  lib,
  buildPythonPackage,
  fetchFromGitHub,

  # build-system
  hatch-vcs,
  hatchling,

  # dependencies
  numpy,
  packaging,
  pydantic,

  # tests
  dask,
  pytest-examples,
  pytestCheckHook,
  xarray,
}:

buildPythonPackage (finalAttrs: {
  pname = "pydantic-zarr";
  version = "0.10.0";
  pyproject = true;
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "zarr-developers";
    repo = "pydantic-zarr";
    tag = "v${finalAttrs.version}";
    hash = "sha256-SzvYiZWnknGdJexYnGEWQaVQpHo1520RaNjuzCA4xtQ=";
  };

  # pytest 9.1 rejects generators in parametrize when warnings are errors.
  postPatch = ''
    substituteInPlace tests/test_docs/test_docs.py \
      --replace-fail 'find_examples(str(SOURCES_ROOT))' 'list(find_examples(str(SOURCES_ROOT)))' \
      --replace-fail 'find_examples("docs")' 'list(find_examples("docs"))'
  '';

  build-system = [
    hatch-vcs
    hatchling
  ];

  dependencies = [
    numpy
    packaging
    pydantic
  ];

  pythonImportsCheck = [ "pydantic_zarr" ];

  nativeCheckInputs = [
    dask
    pytest-examples
    pytestCheckHook
    xarray
  ];

  meta = {
    description = "Pydantic models for Zarr";
    homepage = "https://github.com/zarr-developers/pydantic-zarr";
    changelog = "https://github.com/zarr-developers/pydantic-zarr/releases/tag/${finalAttrs.src.tag}";
    license = with lib.licenses; [
      bsd3
      mit
    ];
    maintainers = with lib.maintainers; [ GaetanLepage ];
  };
})
