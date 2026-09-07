{
  python,
  runCommand,
}:

let
  dependency = python.pkgs.buildPythonPackage {
    pname = "pythonpath-propagation-test-dependency";
    version = "1";
    format = "other";

    dontUnpack = true;
    installPhase = ''
      mkdir -p "$out/${python.sitePackages}" "$out/lib/pythonpath-propagation-test"
      echo "$out/lib/pythonpath-propagation-test" > "$out/${python.sitePackages}/pythonpath-propagation-test.pth"
      echo 'value = "visible"' > "$out/lib/pythonpath-propagation-test/pythonpath_propagation_test_dependency.py"
    '';

    doCheck = false;
  };

  makeApplication =
    propagatePythonPath:
    python.pkgs.buildPythonApplication {
      pname = "pythonpath-propagation-test-application";
      version = "1";
      format = "other";

      inherit propagatePythonPath;
      dependencies = [ dependency ];

      dontUnpack = true;
      installPhase = ''
        mkdir -p "$out/bin"

        cat > "$out/bin/pythonpath-propagation-test" <<'PY'
        #!${python.interpreter}
        import os
        from pathlib import Path
        import subprocess
        import sys

        import pythonpath_propagation_test_dependency as dependency

        if os.environ.get("EXPECT_SENTINEL"):
            assert "/sentinel" in os.environ["PYTHONPATH"].split(os.pathsep)
        print("parent:", dependency.value)
        child = Path(__file__).with_name("pythonpath-propagation-child.py")
        subprocess.run([sys.executable, child], check=True)
        PY
        chmod +x "$out/bin/pythonpath-propagation-test"

        cat > "$out/bin/pythonpath-propagation-child.py" <<'PY'
        from pathlib import Path
        import subprocess
        import sys

        import pythonpath_propagation_test_dependency as dependency

        print("child:", dependency.value)
        grandchild = Path(__file__).with_name("pythonpath-propagation-grandchild.py")
        subprocess.run([sys.executable, grandchild], check=True)
        PY

        cat > "$out/bin/pythonpath-propagation-grandchild.py" <<'PY'
        import pythonpath_propagation_test_dependency as dependency

        print("grandchild:", dependency.value)
        PY
      '';

      doCheck = false;
    };

  isolatedApplication = makeApplication false;
  propagatingApplication = makeApplication true;
in
runCommand "${python.name}-pythonpath-propagation-test" { } ''
  if env -u PYTHONPATH ${isolatedApplication}/bin/pythonpath-propagation-test > isolated.stdout 2> isolated.stderr; then
    echo "Python path unexpectedly leaked into a subprocess" >&2
    exit 1
  fi
  grep -Fx "parent: visible" isolated.stdout
  grep -Fq "No module named 'pythonpath_propagation_test_dependency'" isolated.stderr

  EXPECT_SENTINEL=1 PYTHONPATH=/sentinel ${propagatingApplication}/bin/pythonpath-propagation-test > propagated.stdout
  grep -Fx "parent: visible" propagated.stdout
  grep -Fx "child: visible" propagated.stdout
  grep -Fx "grandchild: visible" propagated.stdout

  touch "$out"
''
