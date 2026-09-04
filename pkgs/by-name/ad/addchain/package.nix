{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
  versionCheckHook,
}:
buildGoModule (finalAttrs: {
  pname = "addchain";
  version = "0.4.0";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "mmcloughlin";
    repo = "addchain";
    tag = "v${finalAttrs.version}";
    fetchSubmodules = false;
    hash = "sha256-msuZgNYqN1QldrbXJJ4BFXYhUsllAPt8W0KRrr8p6TM=";
  };

  vendorHash = "sha256-qxlVGkbm95WFmH0+48XRXwrF7HRUWFxYHFzmFOaj4GA=";

  ldflags = [
    "-s"
    "-X github.com/mmcloughlin/addchain/meta.buildversion=${finalAttrs.version}"
  ];

  subPackages = [ "cmd/addchain" ];

  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "version";
  doInstallCheck = true;

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "addchain generates short addition chains for exponents of cryptographic interest with results rivaling the best hand-optimized chains";
    homepage = "https://github.com/mmcloughlin/addchain";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [
      ambiso
    ];
    mainProgram = "addchain";
  };
})
