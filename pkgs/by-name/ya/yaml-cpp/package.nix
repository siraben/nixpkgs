{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchpatch,
  gitUpdater,
  cmake,
  static ? stdenv.hostPlatform.isStatic,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "yaml-cpp";
  version = "0.9.0";

  src = fetchFromGitHub {
    owner = "jbeder";
    repo = "yaml-cpp";
    tag = "yaml-cpp-${finalAttrs.version}";
    hash = "sha256-+FOsPQY44h1g9tEw3O281LkiYKXdW2jnFKw+oTRkhGw=";
  };

  # Preserve the full Dragonbox significand when size_t is only 32-bit.
  # https://github.com/jbeder/yaml-cpp/pull/1401
  patches = [
    (fetchpatch {
      url = "https://github.com/jbeder/yaml-cpp/commit/ebb85dd462f1d5842f4a059225553ded71c5c5e2.patch";
      hash = "sha256-Ja+dG3TVVZbfwVJPayTrJxGkyZOWQu2s1EV0hv+Lb30=";
    })
  ];

  strictDeps = true;

  nativeBuildInputs = [
    cmake
  ];

  cmakeFlags = [
    (lib.cmakeBool "YAML_CPP_BUILD_TESTS" finalAttrs.finalPackage.doCheck)
    (lib.cmakeBool "YAML_CPP_BUILD_TOOLS" false)
    (lib.cmakeBool "YAML_BUILD_SHARED_LIBS" (!static))
  ];

  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  passthru.updateScript = gitUpdater { rev-prefix = "yaml-cpp-"; };

  meta = {
    description = "YAML parser and emitter for C++";
    homepage = "https://github.com/jbeder/yaml-cpp";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [ OPNA2608 ];
  };
})
