{
  lib,
  buildEnv,
  makeBinaryWrapper,
  runCommand,
  drv,
  extraDependencies ? [ ],
  python,
  requiredPythonModules,
  removePythonPrefix,
}:

let
  runtimeModules = requiredPythonModules (extraDependencies ++ [ drv ]);
  pythonPath = lib.makeSearchPath python.sitePackages runtimeModules;
  runtimePath = lib.makeBinPath runtimeModules;
  emptyBin = runCommand "empty-python-application-bin" { } "mkdir -p $out/bin";
in
buildEnv {
  name = removePythonPrefix drv.name;
  paths = [
    drv
    emptyBin
  ];
  extraOutputsToInstall = drv.meta.outputsToInstall or [ "out" ];

  nativeBuildInputs = [ makeBinaryWrapper ];

  postBuild = ''
    if [ -d "${drv}/bin" ]; then
      for target in "${drv}"/bin/*; do
        if [ -f "$target" ] && [ -x "$target" ]; then
          program="$out/bin/$(basename "$target")"
          rm -f "$program"
          makeWrapper "$target" "$program" \
            --set NIX_PYTHONPREFIX "$out" \
            --set NIX_PYTHONEXECUTABLE "${python.interpreter}" \
            --set NIX_PYTHONPATH "${pythonPath}" \
            --prefix PATH : "${runtimePath}" \
            ${lib.optionalString (!(drv.permitUserSite or false)) ''--set PYTHONNOUSERSITE "true"''} \
            ${lib.concatStringsSep " " (drv.makeWrapperArgs or [ ])}
        fi
      done
    fi
  '';

  inherit (drv) meta;

  passthru = (drv.passthru or { }) // {
    unwrapped = drv;
    pythonModule = false;
    inherit extraDependencies;
    inherit runtimeModules;
  };
}
