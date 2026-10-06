{
  lib,
  stdenv,
  fetchFromGitLab,
  fetchFromGitHub,
  replaceVars,
  symlinkJoin,
  cmake,
  doxygen,
  ruby,
  validatePkgConfig,
  testers,
  unity-test,
  ctestCheckHook,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "iniparser";
  version = "4.2.6";

  src = fetchFromGitLab {
    owner = "iniparser";
    repo = "iniparser";
    tag = "v${finalAttrs.version}";
    hash = "sha256-z10S9ODLprd7CbL5Ecgh7H4eOwTetYwFXiWBUm6fIr4=";
  };

  patches = lib.optional finalAttrs.finalPackage.doCheck (
    # 1. Do not fetch the Unity GitHub repository
    # 2. Lookup the Unity pkgconfig file
    # 3. Get the generate_test_runner.rb file from the Unity share directory
    replaceVars ./remove-fetchcontent-usage.patch {
      # Get the test generator
      UNITY-GENERATE-TEST-RUNNER = "${unity-test}/share/generate_test_runner.rb";
    }
  );

  nativeBuildInputs = [
    cmake
    doxygen
    validatePkgConfig
  ];

  cmakeFlags = [
    (lib.cmakeBool "BUILD_TESTING" finalAttrs.finalPackage.doCheck)
  ];
  # Unity only auto-enables 64-bit integer assertions on 64-bit targets.
  # Both the test runner and the Unity library need them for get{u,}int64.
  env.NIX_CFLAGS_COMPILE = lib.optionalString stdenv.hostPlatform.is32bit "-DUNITY_SUPPORT_64";

  doCheck = true;
  nativeCheckInputs = [
    ruby
    ctestCheckHook
  ];
  checkInputs = [
    (
      (unity-test.override {
        supportDouble = true;
      }).overrideAttrs
        {
          doCheck = false;
          env.NIX_CFLAGS_COMPILE = lib.optionalString stdenv.hostPlatform.is32bit "-DUNITY_SUPPORT_64";
        }
    )
  ];

  postFixup = ''
    ln -sv $out/include/iniparser/*.h $out/include/
  '';

  strictDeps = true;

  passthru.tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;

  meta = {
    homepage = "https://gitlab.com/iniparser/iniparser";
    description = "Free standalone ini file parsing library";
    changelog = "https://gitlab.com/iniparser/iniparser/-/releases/v${finalAttrs.version}";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    pkgConfigModules = [ "iniparser" ];
    maintainers = [ ];
  };
})
