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
  writeText,
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

  userSiteIsolationTests = lib.optionalAttrs python.isPy3k (
    let
      testDriver = writeText "python-user-site-isolation-test.py" ''
        import os
        import subprocess
        import sys

        mode = sys.argv[1]
        expect_user_site = mode == "permitted"

        try:
            import user_site_marker
        except ModuleNotFoundError:
            has_user_site = False
        else:
            has_user_site = user_site_marker.VALUE == "found"

        assert has_user_site == expect_user_site
        assert bool(sys.flags.no_user_site) != expect_user_site
        assert "NIX_PYTHONNOUSERSITE" not in os.environ

        if mode == "caller":
            assert os.environ.get("PYTHONNOUSERSITE") == "caller-value"
        else:
            assert "PYTHONNOUSERSITE" not in os.environ

        if len(sys.argv) > 2:
            if mode == "caller":
                child_code = """
        import os
        assert os.environ.get('PYTHONNOUSERSITE') == 'caller-value'
        """
            else:
                child_code = """
        import os
        import user_site_marker
        assert user_site_marker.VALUE == 'found'
        assert 'PYTHONNOUSERSITE' not in os.environ
        assert 'NIX_PYTHONNOUSERSITE' not in os.environ
        """
            subprocess.run([os.environ["CHILD_PYTHON"], "-c", child_code], check=True)
      '';
      mkTestProgram =
        {
          name,
          permitUserSite ? false,
        }:
        python.pkgs.buildPythonApplication {
          pname = "python-user-site-isolation-${name}";
          version = "0";
          format = "other";
          dontUnpack = true;
          inherit permitUserSite;

          installPhase = ''
            mkdir -p $out/bin

            make_test_script() {
              local destination=$1
              local interpreterFlag=$2
              {
                echo "#!${python.interpreter}$interpreterFlag"
                cat ${testDriver}
              } > "$destination"
              chmod +x "$destination"
            }

            make_test_script "$out/bin/user-site-${name}" ""
            make_test_script "$out/bin/user-site-${name}-no-site" " -S"
          '';
        };
      defaultProgram = mkTestProgram { name = "default"; };
      permittedProgram = mkTestProgram {
        name = "permitted";
        permitUserSite = true;
      };
      defaultEnv = python.withPackages (_: [ ]);
      permittedEnv = python.buildEnv.override {
        extraLibs = [ ];
        permitUserSite = true;
      };
    in
    {
      user-site-isolation = runCommand "${python.name}-user-site-isolation-test" { } ''
        export PYTHONUSERBASE=$TMPDIR/userbase
        export CHILD_PYTHON=${python.interpreter}
        userSite="$(
          env -u PYTHONNOUSERSITE -u NIX_PYTHONNOUSERSITE \
            ${python.interpreter} -c 'import site; print(site.getusersitepackages())'
        )"
        mkdir -p "$userSite"
        echo 'VALUE = "found"' > "$userSite/user_site_marker.py"

        run_without_user_site_variables() {
          env -u PYTHONNOUSERSITE -u NIX_PYTHONNOUSERSITE "$@"
        }

        run_without_user_site_variables \
          ${defaultEnv.interpreter} ${testDriver} isolated child
        run_without_user_site_variables \
          ${defaultEnv.interpreter} -S ${testDriver} isolated child
        ${lib.optionalString (python.implementation == "cpython") ''
          run_without_user_site_variables \
            ${defaultEnv}/bin/python -S ${testDriver} isolated child
        ''}
        run_without_user_site_variables \
          ${defaultProgram}/bin/user-site-default isolated child
        run_without_user_site_variables \
          ${defaultProgram}/bin/user-site-default-no-site isolated child

        run_without_user_site_variables \
          ${permittedEnv.interpreter} ${testDriver} permitted
        run_without_user_site_variables \
          ${permittedProgram}/bin/user-site-permitted permitted

        PYTHONNOUSERSITE=caller-value \
          ${defaultEnv.interpreter} ${testDriver} caller child

        touch $out
      '';
    }
  );

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

in
lib.optionalAttrs (stdenv.hostPlatform == stdenv.buildPlatform) (
  environmentTests
  // integrationTests
  // userSiteIsolationTests
  // overrideTests
  // condaTests
  // editableTests
)
