# Test that buildLakePackage works with nix-only deps (empty lake-manifest.json).
# Builds a Lean proof of the weak minimax inequality using mathlib.
{
  leanPackages,
  runCommand,
}:

let
  inherit (leanPackages) buildLakePackage mathlib;

  testPackage = buildLakePackage {
    pname = "weak-minimax";
    version = "0";
    src = ./.;

    leanDeps = [ mathlib ];

    # Ensure this build exercises setup.json installation cleanup.
    postBuild = ''
      test -d .lake/build/ir
      test -n \
        "$(find .lake/build/ir -type f -name '*.setup.json' -print -quit)"
    '';
  };
in

runCommand "buildLakePackage-weak-minimax" { } ''
  mkdir -p $out

  # Verify library output has compiled oleans.
  test -d "${testPackage}/.lake/build/lib/lean"

  # Build-only compiler setup metadata must not be installed.
  test -d "${testPackage}/.lake/build/ir"
  test -z "$(
    find "${testPackage}/.lake/build/ir" -type f -name '*.setup.json' -print -quit
  )"
  touch $out/success
''
