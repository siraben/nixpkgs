{
  lib,
  buildPythonPackage,
  cargo,
  fetchFromGitHub,
  nix-update-script,
  orjson,
  pydantic,
  pytest-asyncio,
  pytestCheckHook,
  rustc,
  rustPlatform,
}:

buildPythonPackage (finalAttrs: {
  pname = "blastdns";
  version = "1.9.1-unstable-2026-04-15";
  pyproject = true;

  __structuredAttrs = true;

  __darwinAllowLocalNetworking = true;

  src = fetchFromGitHub {
    owner = "blacklanternsecurity";
    repo = "blastdns";
    rev = "a35704b0ec2f6d800da8f85505bfff1893172869";
    hash = "sha256-N0IbnKz/JdZogJhRHMNaZhhMt2LM9Vhs1ETLqeksE2k=";
  };

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname version src;
    hash = "sha256-wBC/T/XUSfxurujQy/B8zXxZthpUWczKT9qdnG4BK7w=";
  };

  build-system = [
    cargo
    rustPlatform.cargoSetupHook
    rustPlatform.maturinBuildHook
    rustc
  ];

  dependencies = [
    orjson
    pydantic
  ];

  nativeCheckInputs = [
    pytest-asyncio
    pytestCheckHook
  ];

  # Run tests outside the source package path so imports resolve to the
  # installed wheel, which contains the compiled _native extension.
  preCheck = ''
    cp -r blastdns/tests "$TMPDIR/tests"
    cd "$TMPDIR"
  '';

  pytestFlags = [
    "--import-mode=importlib"
    "tests"
  ];

  disabledTests = [
    # Tests requires host system DNS config files that are absent in sandboxed builds.
    "test_get_system_resolvers"
    "test_client_resolve"
    "test_mock_matches_real_client"
    "test_zone_transfer_success"
    "test_zone_transfer_nonexistent_zone"
    # Sends DNS traffic to TEST-NET; the sandbox/network may redirect or block
    # it without the resolver error this integration test expects.
    "test_unreachable_resolver_raises_resolver_error"
  ];

  pythonImportsCheck = [ "blastdns" ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Ultra-fast DNS resolver";
    homepage = "https://github.com/blacklanternsecurity/blastdns";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ fab ];
  };
})
