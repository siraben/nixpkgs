# Tests for the Python interpreters, package sets and environments.
#
# Each Python interpreter has a `passthru.tests` which is the attribute set
# returned by this function. For example, for Python 3 the tests are run with
#
# $ nix-build -A python3.tests
#
{
  stdenv,
  python,
  runCommand,
  lib,
  callPackage,
  pkgs,
}:

let
  # Test whether the interpreter behaves in the different types of environments
  # we aim to support.
  environmentTests =
    let
      environments =
        let
          inherit python;
          pythonEnv = python.withPackages (ps: [ ]);
          pythonVirtualEnv =
            if python.isPy3k then
              python.withPackages (ps: with ps; [ virtualenv ])
            else
              python.buildEnv.override {
                extraLibs = with python.pkgs; [ virtualenv ];
                # Collisions because of namespaces __init__.py
                ignoreCollisions = true;
              };
        in
        {
          # Plain Python interpreter
          plain = rec {
            environment = python;
            interpreter = environment.interpreter;
            is_venv = "False";
            is_nixenv = "False";
            is_virtualenv = "False";
          };
        }
        // lib.optionalAttrs (!python.isPyPy && !stdenv.hostPlatform.isDarwin) {
          # Use virtualenv from a Nix env.
          # Fails on darwin with
          #   virtualenv: error: argument dest: the destination . is not write-able at /nix/store
          nixenv-virtualenv = rec {
            environment = runCommand "${python.name}-virtualenv" { } ''
              ${pythonVirtualEnv.interpreter} -m virtualenv venv
              mv venv $out
            '';
            interpreter = "${environment}/bin/${python.executable}";
            is_venv = "False";
            is_nixenv = "True";
            is_virtualenv = "True";
          };
        }
        // lib.optionalAttrs (python.implementation != "graal") {
          # Python Nix environment (python.buildEnv)
          nixenv = rec {
            environment = pythonEnv;
            interpreter = environment.interpreter;
            is_venv = "False";
            is_nixenv = "True";
            is_virtualenv = "False";
          };
        }
        // lib.optionalAttrs (python.isPy3k && (!python.isPyPy)) {
          # Venv built using plain Python
          # Python 2 does not support venv
          # TODO: PyPy executable name is incorrect, it should be pypy-c or pypy-3c instead of pypy and pypy3.
          plain-venv = rec {
            environment = runCommand "${python.name}-venv" { } ''
              ${python.interpreter} -m venv $out
            '';
            interpreter = "${environment}/bin/${python.executable}";
            is_venv = "True";
            is_nixenv = "False";
            is_virtualenv = "False";
          };

        }
        // {
          # Venv built using Python Nix environment (python.buildEnv)
          # TODO: Cannot create venv from a  nix env
          # Error: Command '['/nix/store/ddc8nqx73pda86ibvhzdmvdsqmwnbjf7-python3-3.7.6-venv/bin/python3.7', '-Im', 'ensurepip', '--upgrade', '--default-pip']' returned non-zero exit status 1.
          nixenv-venv = rec {
            environment = runCommand "${python.name}-venv" { } ''
              ${pythonEnv.interpreter} -m venv $out
            '';
            interpreter = "${environment}/bin/${pythonEnv.executable}";
            is_venv = "True";
            is_nixenv = "True";
            is_virtualenv = "False";
          };
        };

      testfun =
        name: attrs:
        runCommand "${python.name}-tests-${name}"
          (
            {
              inherit (python) pythonVersion;
            }
            // attrs
          )
          ''
            cp -r ${./tests/test_environments} tests
            chmod -R +w tests
            substituteAllInPlace tests/test_python.py
            ${attrs.interpreter} -m unittest discover --verbose tests #/test_python.py
            mkdir $out
            touch $out/success
          '';

    in
    lib.mapAttrs testfun environments;

  # Integration tests involving the package set.
  # All PyPy package builds are broken at the moment
  integrationTests = lib.optionalAttrs (!python.isPyPy) (
    {
      # Make sure tkinter is importable. See https://github.com/NixOS/nixpkgs/issues/238990
      tkinter = callPackage ./tests/test_tkinter {
        interpreter = python;
      };
    }
    // lib.optionalAttrs (python.isPy3k && python.pythonOlder "3.13" && !stdenv.hostPlatform.isDarwin) {
      # darwin has no split-debug
      # fails on python3.13
      cpython-gdb = callPackage ./tests/test_cpython_gdb {
        interpreter = python;
      };
    }
    // lib.optionalAttrs (python.isPy3k && python.pythonOlder "3.13") {
      # Before the addition of NIX_PYTHONPREFIX mypy was broken with typed packages
      # mypy does not yet support python3.13
      # https://github.com/python/mypy/issues/17264
      nix-pythonprefix-mypy = callPackage ./tests/test_nix_pythonprefix {
        interpreter = python;
      };
    }
  );

  # Test editable package support
  editableTests =
    let
      testPython = python.override {
        self = testPython;
        packageOverrides = pyfinal: pyprev: {
          # An editable package with a script that loads our mutable location
          my-editable = pyfinal.mkPythonEditablePackage {
            pname = "my-editable";
            version = "0.1.0";
            root = "$NIX_BUILD_TOP/src"; # Use environment variable expansion at runtime
            # Inject a script
            scripts = {
              my-script = "my_editable.main:main";
            };
          };
        };
      };

    in
    {
      editable-script =
        runCommand "editable-test"
          {
            nativeBuildInputs = [ (testPython.withPackages (ps: [ ps.my-editable ])) ];
          }
          ''
            mkdir -p src/my_editable

            cat > src/my_editable/main.py << EOF
            def main():
              print("hello mutable")
            EOF

            test "$(my-script)" == "hello mutable"
            test "$(python -c 'import sys; print(sys.path[1])')" == "$NIX_BUILD_TOP/src"

            touch $out
          '';
    };

  # Tests to ensure overriding works as expected.
  overrideTests =
    let
      extension = self: super: {
        foobar = super.numpy;
      };
      # `pythonInterpreters.pypy39_prebuilt` does not expose an attribute
      # name (is not present in top-level `pkgs`).
      is_prebuilt = python: python.pythonAttr == null;
    in
    lib.optionalAttrs (python.isPy3k) (
      {
        test-packageOverrides =
          let
            myPython =
              let
                self = python.override {
                  packageOverrides = extension;
                  inherit self;
                };
              in
              self;
          in
          assert myPython.pkgs.foobar == myPython.pkgs.numpy;
          myPython.withPackages (ps: with ps; [ foobar ]);
        # overrideScope is broken currently
        # test-overrideScope = let
        #  myPackages = python.pkgs.overrideScope extension;
        # in assert myPackages.foobar == myPackages.numpy; myPackages.python.withPackages(ps: with ps; [ foobar ]);
        #
        # Have to skip prebuilt python as it's not present in top-level
        # `pkgs` as an attribute.
      }
      // lib.optionalAttrs (python ? pythonAttr && !is_prebuilt python) {
        # Test applying overrides using pythonPackagesOverlays.
        test-pythonPackagesExtensions =
          let
            pkgs_ = pkgs.extend (
              final: prev: {
                pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
                  (python-final: python-prev: {
                    foo = python-prev.setuptools;
                  })
                ];
              }
            );
          in
          pkgs_.${python.pythonAttr}.pkgs.foo;
      }
    );

  # depends on mypy, which depends on CPython internals
  condaTests = lib.optionalAttrs (!python.isPyPy) (
    let
      requests = callPackage (
        {
          autoPatchelfHook,
          fetchurl,
          pythonCondaPackages,
        }:
        python.pkgs.buildPythonPackage {
          pname = "requests";
          version = "2.24.0";
          pyproject = false;
          src = fetchurl {
            url = "https://repo.anaconda.com/pkgs/main/noarch/requests-2.24.0-py_0.tar.bz2";
            sha256 = "02qzaf6gwsqbcs69pix1fnjxzgnngwzvrsy65h1d521g750mjvvp";
          };
          nativeBuildInputs = [
            autoPatchelfHook
          ]
          ++ (with python.pkgs; [
            condaUnpackHook
            condaInstallHook
          ]);
          buildInputs = pythonCondaPackages.condaPatchelfLibs;
          propagatedBuildInputs = with python.pkgs; [
            chardet
            idna
            urllib3
            certifi
          ];
        }
      ) { };
      pythonWithRequests = requests.pythonModule.withPackages (ps: [ requests ]);
    in
    lib.optionalAttrs (python.isPy3k && stdenv.hostPlatform.isLinux) {
      condaExamplePackage = runCommand "import-requests" { } ''
        ${pythonWithRequests.interpreter} -c "import requests" > $out
      '';
    }
  );

  dependencyRoleTests =
    let
      mkModule =
        name: marker: dependencies:
        python.pkgs.toPythonModule (
          runCommand name
            {
              pname = name;
              passthru = { inherit dependencies; };
            }
            ''
              mkdir -p "$out/${python.sitePackages}"
              echo ${lib.escapeShellArg marker} > "$out/${python.sitePackages}/${name}-marker"
            ''
        );

      cycleA = mkModule "cycle-a" "a" [ cycleB ];
      cycleB = mkModule "cycle-b" "b" [ cycleA ];
      cycleClosure = python.pkgs.requiredPythonModules [ cycleA ];
      cycleEnvironment = python.withPackages (_: [ cycleA ]);

      nestedDependency = mkModule "same-distribution" "nested" [ ];
      directDependency = mkModule "same-distribution" "direct" [ ];
      parent = mkModule "parent" "parent" [ nestedDependency ];
      precedenceClosure = python.pkgs.requiredPythonModules [
        directDependency
        parent
      ];

      runtimeV1 = mkModule "runtime-sentinel" "v1" [ ];
      runtimeV2 = mkModule "runtime-sentinel" "v2" [ ];
      source = pkgs.writeText "dependency-roles-pyproject.toml" ''
        [build-system]
        build-backend = "setuptools.build_meta"
      '';
      packageFor =
        dependency:
        python.pkgs.buildPythonPackage {
          pname = "dependency-roles-test";
          version = "1";
          pyproject = true;
          src = source;
          build-system = [ python.pkgs.setuptools ];
          dependencies = [ dependency ];
          pythonImportsCheck = [ "dependency_roles_test" ];
          installCheckPhase = "touch $out/checked";
        };
      packageV1 = packageFor runtimeV1;
      packageV2 = packageFor runtimeV2;
      packageWithDifferentTests = packageV1.overridePythonAttrs {
        disabledTests = [ "not-a-real-test" ];
      };
      applicationV1 = python.pkgs.toPythonApplication packageV1;
      applicationV2 = python.pkgs.toPythonApplication packageV2;
      applicationWithOverride = applicationV1.override {
        extraDependencies = [ runtimeV2 ];
      };
      builtApplication = python.pkgs.buildPythonApplication {
        pname = "dependency-roles-application";
        version = "1";
        pyproject = true;
        src = source;
        build-system = [ python.pkgs.setuptools ];
        dependencies = [ runtimeV1 ];
        doCheck = false;
      };
      applicationRuntimeV2 = builtApplication.overridePythonAttrs {
        dependencies = [ runtimeV2 ];
      };
      overriddenApplication = builtApplication.overrideAttrs {
        postPatch = "touch override-marker";
      };

      nonPythonInput = runCommand "non-python-propagated-input" { } "touch $out";
      legacyPackage = python.pkgs.buildPythonPackage {
        pname = "legacy-python-propagation-test";
        version = "1";
        pyproject = true;
        src = source;
        build-system = [ python.pkgs.setuptools ];
        propagatedBuildInputs = [
          runtimeV1
          nonPythonInput
        ];
        doCheck = false;
      };
    in
    {
      dependency-roles =
        assert
          map (drv: drv.pname) cycleClosure == [
            python.pname
            "cycle-a"
            "cycle-b"
          ];
        assert
          map (drv: drv.drvPath) precedenceClosure == [
            python.drvPath
            directDependency.drvPath
            parent.drvPath
          ];
        assert packageV1.drvPath == packageV2.drvPath;
        assert packageV1.tests.python.drvPath != packageV2.tests.python.drvPath;
        assert packageV1.drvPath == packageWithDifferentTests.drvPath;
        assert packageV1.tests.python.drvPath != packageWithDifferentTests.tests.python.drvPath;
        assert applicationV1.unwrapped.drvPath == applicationV2.unwrapped.drvPath;
        assert applicationV1.drvPath != applicationV2.drvPath;
        assert lib.elem runtimeV2.drvPath (map (drv: drv.drvPath) applicationWithOverride.runtimeModules);
        assert
          !(lib.elem runtimeV1.drvPath (map (drv: drv.drvPath) applicationWithOverride.runtimeModules));
        assert builtApplication.unwrapped.drvPath == applicationRuntimeV2.unwrapped.drvPath;
        assert builtApplication.drvPath != applicationRuntimeV2.drvPath;
        assert builtApplication.unwrapped.drvPath != overriddenApplication.unwrapped.drvPath;
        assert map (drv: drv.drvPath) legacyPackage.dependencies == [ runtimeV1.drvPath ];
        assert
          map (drv: drv.drvPath) legacyPackage.propagatedBuildInputs == [
            nonPythonInput.drvPath
          ];
        runCommand "${python.name}-dependency-roles"
          {
            nativeBuildInputs = [ cycleEnvironment ];
          }
          ''
            python -c 'import sys; assert sys.version_info.major == 3'
            touch "$out"
          '';
    };

in
lib.optionalAttrs (stdenv.hostPlatform == stdenv.buildPlatform) (
  environmentTests
  // integrationTests
  // overrideTests
  // condaTests
  // editableTests
  // dependencyRoleTests
)
