{
  lib,
  localSystem,
  crossSystem,
  targetSystem ? crossSystem,
  canadianPackages ? null,
  config,
  overlays,
  crossOverlays,
  bootStages,
}:

let
  isCanadianCross = canadianPackages != null;
in
assert lib.assertMsg
  (!isCanadianCross || (targetSystem.libc == null && (targetSystem.isElf || targetSystem.isNone)))
  "Canadian cross currently supports GCC C for bare-metal or ELF targets without a target libc/SDK; set targetSystem.libc = null";
lib.init bootStages
++ [

  # Regular native packages
  (
    somePrevStage:
    lib.last bootStages somePrevStage
    // {
      # It's OK to change the built-time dependencies
      allowCustomOverrides = true;
    }
  )

  # Build tool Packages
  (
    vanillaPackages:
    {
      inherit config overlays;
      selfBuild = false;
      stdenv =
        assert vanillaPackages.stdenv.buildPlatform == localSystem;
        assert vanillaPackages.stdenv.hostPlatform == localSystem;
        assert vanillaPackages.stdenv.targetPlatform == localSystem;
        vanillaPackages.stdenv.override { targetPlatform = crossSystem; };
      # It's OK to change the built-time dependencies
      allowCustomOverrides = true;
    }
    // lib.optionalAttrs isCanadianCross {
      # The next stage is B/H/T rather than B/H/H. Keep this B/B/H stage's
      # ordinary neighbours instead of accidentally pointing it at B/H/T.
      adjacentPackages = {
        pkgsBuildBuild = canadianPackages.host.pkgsBuildBuild;
        pkgsBuildHost = canadianPackages.host.pkgsBuildBuild;
        pkgsBuildTarget = canadianPackages.host.buildPackages;
        pkgsHostHost = canadianPackages.host.pkgsBuildBuild;
        pkgsTargetTarget = canadianPackages.host;
      };
    }
  )

  # Run Packages
  (
    buildPackages:
    let
      adaptStdenv = if crossSystem.isStatic then buildPackages.stdenvAdapters.makeStatic else lib.id;
      stdenvNoCC = adaptStdenv (
        buildPackages.stdenv.override (
          old:
          rec {
            buildPlatform = localSystem;
            hostPlatform = crossSystem;
            targetPlatform = targetSystem;

            # Prior overrides are surely not valid as packages built with this run on
            # a different platform, and so are disabled.
            overrides = _: _: { };
            extraBuildInputs = [ ]; # Old ones run on wrong platform
            allowedRequisites = null;

            cc = null;
            hasCC = false;

            extraNativeBuildInputs =
              old.extraNativeBuildInputs
              ++ lib.optionals (hostPlatform.isLinux && !buildPlatform.isLinux) [ buildPackages.patchelf ]
              ++ lib.optional (
                let
                  f =
                    p:
                    !p.isx86
                    || builtins.elem p.libc [
                      "musl"
                      "wasilibc"
                      "relibc"
                    ]
                    || p.isiOS
                    || p.isGenode;
                in
                f hostPlatform && !(f buildPlatform)
              ) buildPackages.updateAutotoolsGnuConfigScriptsHook
              ++ lib.optional (
                hostPlatform.isCygwin && !buildPlatform.isCygwin
              ) buildPackages.cygwin.cygwinDllLinkHook;
          }
          // lib.optionalAttrs isCanadianCross {
            extraAttrs = (old.extraAttrs or { }) // {
              inherit isCanadianCross;
            };
          }
        )
      );
    in
    {
      inherit config;
      overlays = overlays ++ crossOverlays;
      selfBuild = false;
      inherit stdenvNoCC;
      stdenv =
        let
          inherit (stdenvNoCC) hostPlatform;
          baseStdenv = stdenvNoCC.override {
            # Old ones run on wrong platform
            extraBuildInputs = lib.optionals hostPlatform.isDarwin [
              buildPackages.targetPackages.apple-sdk
            ];

            hasCC = !hostPlatform.isGhcjs;

            cc =
              if crossSystem.useiOSPrebuilt or false then
                buildPackages.darwin.iosSdkPkgs.clang
              else if crossSystem.useAndroidPrebuilt or false then
                buildPackages."androidndkPkgs_${crossSystem.androidNdkVersion}".clang
              else if
                hostPlatform.isGhcjs
              # Need to use `throw` so tryEval for splicing works, ugh.  Using
              # `null` or skipping the attribute would cause an eval failure
              # `tryEval` wouldn't catch, wrecking accessing previous stages
              # when there is a C compiler and everything should be fine.
              then
                throw "no C compiler provided for this platform"
              else if crossSystem.isDarwin then
                buildPackages.llvmPackages.systemLibcxxClang
              else if crossSystem.useLLVM or false then
                buildPackages.llvmPackages.clang
              else if crossSystem.useZig or false then
                buildPackages.zig.cc
              else if crossSystem.useArocc or false then
                buildPackages.arocc
              else if crossSystem.useGccNG or false then
                buildPackages.gccNGPackages.gcc
              else
                buildPackages.gcc;

          };
        in
        if config ? replaceCrossStdenv then
          config.replaceCrossStdenv { inherit buildPackages baseStdenv; }
        else
          baseStdenv;
    }
    // lib.optionalAttrs isCanadianCross {
      # B/H/T needs B/B/T and B/H/H independently; neither is obtained by
      # sliding the normal three-stage cross chain one step forwards/backwards.
      adjacentPackages = {
        pkgsBuildBuild = canadianPackages.host.pkgsBuildBuild;
        pkgsBuildHost = canadianPackages.host.buildPackages;
        pkgsBuildTarget = canadianPackages.target.buildPackages;
        pkgsHostHost = canadianPackages.host;
        pkgsTargetTarget = canadianPackages.target;
      };
    }
  )

]
