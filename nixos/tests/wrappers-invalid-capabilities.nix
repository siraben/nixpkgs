# Build-time regression test for security wrapper capability validation.
{
  lib,
  runCommand,
  testers,
  evalSystem,
}:
let
  config =
    (evalSystem {
      imports = [
        ({ pkgs, ... }: {
          security.wrappers.duplicateCapabilities = {
            source = "${pkgs.hello}/bin/hello";
            owner = "root";
            group = "root";
            capabilities = "cap_sys_nice+ep";
          };
        })
        {
          security.wrappers.duplicateCapabilities.capabilities = "cap_sys_nice+pie";
        }
      ];
    }).config;

  wrappersCheck = lib.findFirst (
    check: check.name == "ensure-all-wrappers-paths-exist"
  ) (throw "security wrappers check not found") config.system.checks;
in
assert
  config.security.wrappers.duplicateCapabilities.capabilities == "cap_sys_nice+ep,cap_sys_nice+pie";
runCommand "wrappers-invalid-capabilities-test"
  {
    failed = testers.testBuildFailure wrappersCheck;
  }
  ''
    grep -F 'cap_from_text: Invalid argument' "$failed/testBuildFailure.log"
    grep -F 'The capability cap_sys_nice+ep,cap_sys_nice+pie is invalid!' "$failed/testBuildFailure.log"
    grep -F 'Please, check the value of `security.wrappers."duplicateCapabilities".capabilities`.' \
      "$failed/testBuildFailure.log"
    [[ 1 = $(<"$failed/testBuildFailure.exit") ]]
    touch "$out"
  ''
