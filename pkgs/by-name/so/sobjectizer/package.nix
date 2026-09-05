{
  pkgs,
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  withStatic ? stdenv.hostPlatform.isStatic,
  withShared ? !withStatic,
  buildExamples ? false,
}:

# Ensure build examples with static library.
assert buildExamples -> withStatic;

stdenv.mkDerivation (finalAttrs: {
  pname = "sobjectizer";
  version = "5.8.6";

  src = fetchFromGitHub {
    owner = "Stiffstream";
    repo = "sobjectizer";
    tag = "v${finalAttrs.version}";
    hash = "sha256-PsdI9QoqaxT8CUmxo1SaeqvoN7eRh/FcWNrGSP1BG/A=";
  };

  nativeBuildInputs = [ cmake ];

  cmakeDir = "../dev";

  cmakeFlags = [
    (lib.cmakeBool "SOBJECTIZER_BUILD_STATIC" withStatic)
    (lib.cmakeBool "SOBJECTIZER_BUILD_SHARED" withShared)
    (lib.cmakeBool "BUILD_EXAMPLES" (buildExamples && withStatic))
    (lib.cmakeBool "BUILD_TESTS" (finalAttrs.finalPackage.doCheck && withShared))
  ];

  # The tests require the shared library.
  doCheck = withShared;

  # Receive semi-automated updates.
  passthru.updateScript = pkgs.nix-update-script { };

  meta = {
    homepage = "https://github.com/Stiffstream/sobjectizer/tree/master";
    changelog = "https://github.com/Stiffstream/sobjectizer/releases/tag/v${finalAttrs.version}";
    description = "Implementation of Actor, Publish-Subscribe, and CSP models in one rather small C++ framework";
    license = lib.licenses.bsd3;
    maintainers = [ lib.maintainers.ivalery111 ];
    platforms = lib.platforms.all;
  };
})
