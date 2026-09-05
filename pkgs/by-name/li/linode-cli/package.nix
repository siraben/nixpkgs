{
  stdenv,
  fetchPypi,
  fetchurl,
  installShellFiles,
  lib,
  python3Packages,
}:

let
  hash = "sha256-w68dxhf4vBZLqp6YAg6XmyDF7mttNUFCdvPCaB2YNQc=";
  specVersion = "release-20260527";
  specHash = "sha256-ShXQt4pp8rJNmfNFy1+QgRKWM3xJHiGDuN0FkAVuFtc=";
  spec = fetchurl {
    url = "https://raw.githubusercontent.com/linode/linode-api-openapi/${specVersion}/openapi.json";
    hash = specHash;
  };

in

python3Packages.buildPythonApplication (finalAttrs: {
  pname = "linode-cli";
  version = "5.68.0";
  pyproject = true;

  src = fetchPypi {
    pname = "linode_cli";
    inherit (finalAttrs) version;
    hash = hash;
  };

  build-system = [
    python3Packages.setuptools
  ];

  patches = [ ./remove-update-check.patch ];

  postConfigure = ''
    python3 -m linodecli bake ${spec} --skip-config
    cp data-3 linodecli/
    echo "${finalAttrs.version}" > baked_version
  '';

  nativeBuildInputs = [ installShellFiles ];

  dependencies = [
    python3Packages.linode-metadata
    python3Packages.openapi3
    python3Packages.packaging
    python3Packages.pytimeparse
    python3Packages.pyyaml
    python3Packages.requests
    python3Packages.rich
    python3Packages.urllib3
  ];

  doInstallCheck = true;
  installCheckPhase = ''
    $out/bin/linode-cli --skip-config --version | grep ${finalAttrs.version} > /dev/null
  '';

  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    for shell in bash fish; do
      installShellCompletion --cmd linode-cli \
        --$shell <($out/bin/linode-cli --skip-config completion $shell)
      done
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Linode Command Line Interface";
    changelog = "https://github.com/linode/linode-cli/releases/tag/v${finalAttrs.version}";
    downloadPage = "https://pypi.org/project/linode-cli";
    homepage = "https://github.com/linode/linode-cli";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [
      ryantm
      techknowlogick
    ];
    mainProgram = "linode-cli";
  };
})
