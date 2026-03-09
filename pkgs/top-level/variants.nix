/*
  This file contains all of the different variants of nixpkgs instances.

  Unlike the other package sets like pkgsCross, pkgsi686Linux, etc., this
  contains non-critical package sets. The intent is to be a shorthand
  for things like using different toolchains in every package in nixpkgs.
*/
{
  lib,
  stdenv,
  nixpkgsFun,
  overlays,
}:
let
  makeLLVMParsedPlatform =
    parsed:
    (
      parsed
      // {
        abi = lib.systems.parse.abis.llvm;
      }
    );
in
self: super: {
  pkgsLLVM = nixpkgsFun {
    overlays = [
      (self': super': {
        pkgsLLVM = super';
      })
    ]
    ++ overlays;
    # Bootstrap a cross stdenv using the LLVM toolchain.
    # This is currently not possible when compiling natively,
    # so we don't need to check hostPlatform != buildPlatform.
    crossSystem = stdenv.hostPlatform // {
      useLLVM = true;
      linker = "lld";
    };
  };

  pkgsArocc = nixpkgsFun {
    overlays = [
      (self': super': {
        pkgsArocc = super';
      })
    ]
    ++ overlays;
    # Bootstrap a cross stdenv using the Aro C compiler.
    # This is currently not possible when compiling natively,
    # so we don't need to check hostPlatform != buildPlatform.
    crossSystem = stdenv.hostPlatform // {
      useArocc = true;
      linker = "lld";
    };
  };

  pkgsZig = nixpkgsFun {
    overlays = [
      (self': super': {
        pkgsZig = super';
      })
    ]
    ++ overlays;
    # Bootstrap a cross stdenv using the Zig toolchain.
    # This is currently not possible when compiling natively,
    # so we don't need to check hostPlatform != buildPlatform.
    crossSystem = stdenv.hostPlatform // {
      useZig = true;
      linker = "lld";
    };
  };

  # All packages built with the Musl libc. This will override the
  # default GNU libc on Linux systems. Non-Linux systems are not
  # supported. 32-bit is also not supported, except for x86.
  pkgsMusl =
    if stdenv.hostPlatform.isLinux && (stdenv.buildPlatform.is64bit || stdenv.buildPlatform.isx86) then
      nixpkgsFun {
        overlays = [
          (self': super': {
            pkgsMusl = super';
          })
        ]
        ++ overlays;
        ${if stdenv.hostPlatform == stdenv.buildPlatform then "localSystem" else "crossSystem"} = {
          config = lib.systems.parse.tripleFromSystem (
            lib.systems.parse.mkMuslSystem stdenv.hostPlatform.parsed
          );
        };
      }
    else
      throw "Musl libc only supports 64-bit Linux systems, and i686-linux.";

  # x86_64-darwin packages for aarch64-darwin users to use with Rosetta for incompatible packages
  pkgsx86_64Darwin =
    if stdenv.hostPlatform.isDarwin then
      nixpkgsFun {
        overlays = [
          (self': super': {
            pkgsx86_64Darwin = super';
          })
        ]
        ++ overlays;
        localSystem = {
          config = lib.systems.parse.tripleFromSystem (
            stdenv.hostPlatform.parsed
            // {
              cpu = lib.systems.parse.cpuTypes.x86_64;
            }
          );
        };
      }
    else
      throw "x86_64 Darwin package set can only be used on Darwin systems.";

  # Full package set with rocm on cuda off
  # Mostly useful for asserting pkgs.pkgsRocm.torchWithRocm == pkgs.torchWithRocm and similar
  pkgsRocm = nixpkgsFun {
    config = super.config // {
      cudaSupport = false;
      rocmSupport = true;
    };
  };

  # Full package set with cuda on rocm off
  # Mostly useful for asserting pkgs.pkgsCuda.torchWithCuda == pkgs.torchWithCuda and similar
  pkgsCuda = nixpkgsFun {
    config = super.config // {
      cudaSupport = true;
      rocmSupport = false;
    };
  };

  # `pkgsForCudaArch` maps each CUDA capability in _cuda.db.cudaCapabilityToInfo to a Nixpkgs variant configured for
  # that target system. For example, `pkgsForCudaArch.sm_90a.python3Packages.torch` refers to PyTorch built for the
  # Hopper architecture, leveraging architecture-specific features.
  # NOTE: Not every package set is supported on every architecture!
  # See `Using pkgsForCudaArch` in doc/languages-frameworks/cuda.section.md for more information.
  pkgsForCudaArch = lib.listToAttrs (
    lib.map (cudaCapability: {
      name = self._cuda.lib.mkRealArchitecture cudaCapability;
      value = nixpkgsFun {
        config = super.config // {
          cudaSupport = true;
          rocmSupport = false;
          # Not supported by architecture-specific feature sets, so disable for all.
          # Users can choose to build for family-specific feature sets if they wish.
          cudaForwardCompat = false;
          cudaCapabilities = [ cudaCapability ];
        };
      };
    }) (lib.attrNames self._cuda.db.cudaCapabilityToInfo)
  );

  # All packages built with uutils-coreutils instead of GNU coreutils.
  # Non-Linux systems and 32-bit are not supported.
  pkgsUutils =
    if stdenv.hostPlatform.isLinux && stdenv.buildPlatform.is64bit then
      nixpkgsFun {
        overlays = [
          (
            self': super':
            let
              # Bootstrap stages use fetchurlBoot which cannot build Rust
              # packages, so we must not override coreutils there.
              isBootstrapStage = lib.hasPrefix "bootstrap-" (super'.stdenv.name or "");
              uu-coreutils = super'.uutils-coreutils-minimal;
              gnuCoreutils = super'.stdenv.__bootPackages.stdenv.__bootPackages.coreutils;
            in
            {
              pkgsUutils = super';
            }
            // lib.optionalAttrs (!isBootstrapStage) {
              coreutils = uu-coreutils;
              coreutils-full = super'.uutils-coreutils.override { prefix = null; };
              _bootstrapCoreutils = gnuCoreutils;
              # Break dependency cycles: uutils-coreutils (Rust) has deep deps
              # through python3/cargo. Packages in that chain which reference
              # the `coreutils` parameter must use GNU coreutils to avoid:
              # uutils → vendor → python3 → {openssl,meson,perl,git,...} → coreutils → uutils
              openssl = super'.openssl.override { coreutils = gnuCoreutils; };
              meson = super'.meson.override { coreutils = gnuCoreutils; };
              perl = super'.perl.override { coreutils = gnuCoreutils; };
              deterministic-uname = super'.deterministic-uname.override { coreutils = gnuCoreutils; };
              git = super'.git.override { coreutils = gnuCoreutils; };
              nix-prefetch-git = super'.nix-prefetch-git.override { coreutils = gnuCoreutils; };
              versionCheckHook = super'.versionCheckHook.override { coreutils = gnuCoreutils; };
              wrapBintoolsWith = args: super'.wrapBintoolsWith (args // { coreutils = gnuCoreutils; });
              wrapCCWith = args: super'.wrapCCWith (args // { coreutils = gnuCoreutils; });
              # Override stdenv.overrides to prevent stdenvOverrides (applied last
              # in the overlay chain) from pinning coreutils back to prevStage's
              # GNU coreutils.
              stdenv = super'.stdenv // {
                overrides =
                  self: super:
                  let
                    orig = (super'.stdenv.overrides or (_: _: { })) self super;
                  in
                  removeAttrs orig [ "coreutils" ] // { coreutils = uu-coreutils; };
              };
            }
          )
        ] ++ overlays;
      }
    else
      throw "uutils coreutils variant only supports 64-bit Linux systems.";

  pkgsExtraHardening = nixpkgsFun {
    overlays = [
      (
        self': super':
        {
          pkgsExtraHardening = super';
          stdenv = super'.withDefaultHardeningFlags (
            super'.stdenv.cc.defaultHardeningFlags
            ++ [
              "strictflexarrays1"
              "shadowstack"
              "nostrictaliasing"
              "pacret"
              "glibcxxassertions"
              "libcxxhardeningfast"
              "trivialautovarinit"
            ]
          ) super'.stdenv;
          glibc = super'.glibc.override rec {
            enableCET = if self'.stdenv.hostPlatform.isx86_64 then "permissive" else false;
            enableCETRuntimeDefault = enableCET != false;
          };
        }
        // lib.optionalAttrs (with super'.stdenv.hostPlatform; isx86_64 && isLinux) {
          # causes shadowstack disablement
          pcre = super'.pcre.override { enableJit = false; };
          pcre-cpp = super'.pcre-cpp.override { enableJit = false; };
        }
      )
    ]
    ++ overlays;
  };
}
