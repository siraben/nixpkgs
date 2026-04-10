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
  cosmoCrossOverlays = [
    # Package-specific fixes for cosmopolitan compatibility.
    #
    # Unlike pkgsLLVM/pkgsZig/pkgsMusl which rely on packages handling
    # toolchain differences natively, cosmopolitan libc has unique
    # incompatibilities (non-constexpr errno values, missing POSIX
    # timers, symbol conflicts with gnulib, etc.) that require explicit
    # per-package overrides.  crossOverlays apply these fixes to the
    # cross package set without touching the native packages.
    #
    # Global fixes (gnulib-tests, timespec_cmp, getlocalename_l) and
    # build settings (static-only, no strip/patchelf, .aarch64/ archive
    # copying) are in makeCosmopolitan (adapters.nix).
    (self': super': {
      hello = super'.hello.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          ../development/compilers/cosmocc/hello-no-wprintf.patch
        ];
      });

      ncurses = (super'.ncurses.override { enableStatic = true; }).overrideAttrs (old: {
        # Cosmopolitan declares wcwidth in libc/str/unicode.h, not wchar.h.
        env = (old.env or { }) // {
          NIX_CFLAGS_COMPILE = toString (old.env.NIX_CFLAGS_COMPILE or "") + " -include libc/str/unicode.h";
        };
        configureFlags = (old.configureFlags or [ ]) ++ [
          "--without-dlsym"
          "--with-fallbacks=xterm-256color,tmux-256color,screen-256color,vt100,linux,dumb,xterm,xterm-color"
        ];
        # build-cc lacks cosmo's wint_t prelude.
        preConfigure = (old.preConfigure or "") + ''
          export BUILD_CFLAGS="''${BUILD_CFLAGS:+$BUILD_CFLAGS }-include wchar.h"
        '';
        postInstall = (old.postInstall or "") + ''
          # Replicate the non-wide and tinfo symlinks in .aarch64/
          if [ -d "$out/lib/.aarch64" ]; then
            for f in "$out/lib"/*.a; do
              [ -L "$f" ] || continue
              target="$(readlink "$f")"
              ln -svf "$target" "$out/lib/.aarch64/$(basename "$f")"
            done
          fi
        '';
      });

      gawk = super'.gawk.overrideAttrs (old: {
        configureFlags = (old.configureFlags or [ ]) ++ [
          "--disable-extensions"
        ];
      });

      sqlite = let
        cosmoCC = "${super'.stdenv.cc}/bin/${super'.stdenv.cc.targetPrefix}gcc";
        cosmoAR = "${super'.stdenv.cc.bintools}/bin/${super'.stdenv.cc.targetPrefix}ar";
      in super'.sqlite.overrideAttrs (old: {
        configureFlags = (lib.filter (f: !(lib.hasPrefix "--with-tcl" f)) (old.configureFlags or [ ])) ++ [
          "--disable-tcl"
          "--disable-load-extension"
          "--disable-math"
          "--disable-threadsafe"
        ];
        makeFlags = (lib.filter (f:
          !(lib.hasPrefix "cc=" f) && !(lib.hasPrefix "AR=" f)
        ) (old.makeFlags or [ ])) ++ [
          "cc=${cosmoCC}"
          "AR=${cosmoAR}"
        ];
        env = (old.env or { }) // {
          NIX_CFLAGS_COMPILE = toString (old.env.NIX_CFLAGS_COMPILE or "")
            + " -DSQLITE_ENABLE_MATH_FUNCTIONS -DSQLITE_THREADSAFE=0";
          NIX_LDFLAGS = toString (old.env.NIX_LDFLAGS or "") + " -lm";
        };
        nativeBuildInputs = lib.filter (d: d.pname or "" != "tcl") (old.nativeBuildInputs or [ ]);
        buildInputs = lib.filter (d: d.pname or "" != "tcl") (old.buildInputs or [ ]);
        preConfigure = (old.preConfigure or "") + ''
          export CC="${cosmoCC}"
          export AR="${cosmoAR}"
        '';
      });

      tcl = super'.tcl.overrideAttrs (old: {
        # cosmocc cannot handle arguments containing spaces.
        env = (old.env or { }) // {
          NIX_CFLAGS_COMPILE = toString (old.env.NIX_CFLAGS_COMPILE or "") + " -UPACKAGE_STRING -DPACKAGE_STRING='\"tcl-8.6\"'";
        };
      });

      tzdata = super'.tzdata.overrideAttrs (old: {
        # Cosmopolitan provides mempcpy and issetugid; tell tzdata.
        makeFlags = (old.makeFlags or [ ]) ++ [
          "CFLAGS+=-DHAVE_MEMPCPY=1"
          "CFLAGS+=-DHAVE_ISSETUGID=1"
        ];
      });

      jq = (super'.jq.override { onigurumaSupport = false; }).overrideAttrs (old: {
        # cosmocc rejects arguments containing spaces in DEFS.
        postConfigure = (old.postConfigure or "") + ''
          sed -i 's/-DPACKAGE_STRING=[^ ]*\\ [^ ]*//' Makefile
        '';
        doInstallCheck = false;
      });

      lua = super'.lua.override { staticOnly = true; };

      openssl = super'.openssl.overrideAttrs (old: {
        configureFlags = (old.configureFlags or [ ]) ++ [
          "no-shared"
          "no-ktls"
          "no-asm"
          "no-dso"
          "no-engine"
        ];
      });

      curl = (super'.curl.override {
        zstdSupport = false;
        gssSupport = false;
        http3Support = false;
        http2Support = false;
        brotliSupport = false;
        idnSupport = false;
        pslSupport = false;
        scpSupport = false;
        opensslSupport = false;
        zlibSupport = false;
      }).overrideAttrs (old: {
        configureFlags = (old.configureFlags or [ ]) ++ [
          "--without-librtmp"
        ];
      });

      nghttp3 = super'.nghttp3.overrideAttrs (old: {
        cmakeFlags = (old.cmakeFlags or [ ]) ++ [
          "-DENABLE_SHARED_LIB=OFF"
          "-DENABLE_STATIC_LIB=ON"
        ];
      });

      ngtcp2 = super'.ngtcp2.overrideAttrs (old: {
        cmakeFlags = (old.cmakeFlags or [ ]) ++ [
          "-DENABLE_SHARED_LIB=OFF"
          "-DENABLE_STATIC_LIB=ON"
        ];
      });

      flex = super'.flex.overrideAttrs (old: {
        nativeBuildInputs = lib.filter
          (d: (d.pname or d.name or "") != "autoreconf-hook")
          (old.nativeBuildInputs or [ ]);
        patches = lib.filter
          (p: !(lib.hasInfix "glibc-2.26" (builtins.toString p)))
          (old.patches or [ ]);
        # Clean native binutils paths that collide with cosmocc.
        preConfigure = (old.preConfigure or "") + ''
          export NIX_LDFLAGS_x86_64_unknown_linux_gnu="$(echo "$NIX_LDFLAGS_x86_64_unknown_linux_gnu" | tr ' ' '\n' | grep -v binutils | tr '\n' ' ')"
          export PATH="$(echo "$PATH" | tr ':' '\n' | grep -v 'gcc-wrapper\|binutils-wrapper' | tr '\n' ':')"
        '';
      });

      bison = super'.bison.overrideAttrs (old: {
        # Cosmopolitan declares ffsl in libc/nexgen32e/ffs.h.
        env = (old.env or { }) // {
          NIX_CFLAGS_COMPILE = toString (old.env.NIX_CFLAGS_COMPILE or "") + " -include libc/nexgen32e/ffs.h";
        };
      });

      gnum4 = super'.gnum4.overrideAttrs (old: {
        # tests/ builds gnulib code as part of `make all`.
        postPatch = (old.postPatch or "") + ''
          sed -i '/^SUBDIRS/s/ tests\b//' Makefile.in
        '';
        # Force HAVE_SAME_LONG_DOUBLE_AS_DOUBLE to avoid x87 FPU
        # instructions that don't exist on aarch64 (breaks fat builds).
        env = (old.env or { }) // {
          NIX_CFLAGS_COMPILE = toString (old.env.NIX_CFLAGS_COMPILE or "") + " -DHAVE_SAME_LONG_DOUBLE_AS_DOUBLE=1";
        };
      });

      bc = super'.bc.overrideAttrs (old: {
        # Remove flex from buildInputs (only needed as build tool, not
        # for linking).  Also remove depsBuildBuild and autoreconfHook
        # which pull in the native GCC whose setup hooks collide with
        # cosmocc due to the same target triple.
        buildInputs = lib.filter (d: (d.pname or d.name or "") != "flex")
          (old.buildInputs or [ ]);
        depsBuildBuild = [ ];
        nativeBuildInputs = lib.filter
          (d: (d.pname or d.name or "") != "autoreconf-hook")
          (old.nativeBuildInputs or [ ]);
      });

      gnugrep = (super'.gnugrep.override {
        runtimeShellPackage = null;
      }).overrideAttrs (old: {
        postInstall = "";
        buildInputs = lib.filter (d: !(lib.hasInfix "glibc-iconv" (d.name or ""))) (old.buildInputs or [ ]);
      });
    })
  ];

  mkCosmoVariant =
    name: crossSystem:
    nixpkgsFun {
      overlays = [
        (self': super': {
          ${name} = super';
        })
      ] ++ overlays;
      crossOverlays = cosmoCrossOverlays;
      inherit crossSystem;
    };

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

  pkgsCosmo = mkCosmoVariant "pkgsCosmo" (
    if stdenv.hostPlatform.isLinux && stdenv.hostPlatform.isx86_64
    then stdenv.hostPlatform // { useCosmopolitan = true; }
    else if stdenv.hostPlatform.isAarch64
    then { config = "aarch64-unknown-linux-gnu"; useCosmopolitan = true; cosmoArch = "aarch64"; }
    else { config = "x86_64-unknown-linux-gnu"; useCosmopolitan = true; }
  );

  pkgsCosmoAarch64 = mkCosmoVariant "pkgsCosmoAarch64" lib.systems.examples.cosmo-aarch64;

  pkgsCosmoFat = mkCosmoVariant "pkgsCosmoFat" (
    if stdenv.hostPlatform.isLinux && stdenv.hostPlatform.isx86_64
    then stdenv.hostPlatform // { useCosmopolitan = true; cosmoArch = "fat"; }
    else { config = "x86_64-unknown-linux-gnu"; useCosmopolitan = true; cosmoArch = "fat"; }
  );

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

  pkgsExtraHardening = nixpkgsFun {
    overlays = [
      (
        self': super':
        {
          pkgsExtraHardening = super';
          stdenv = super'.withDefaultHardeningFlags (
            super'.stdenv.cc.defaultHardeningFlags
            ++ [
              "shadowstack"
              "nostrictaliasing"
              "pacret"
              "glibcxxassertions"
              "libcxxhardeningextensive"
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

  pkgsChecked = nixpkgsFun {
    config = super.config // {
      doCheckByDefault = true;
    };
  };
  pkgsParallel = nixpkgsFun {
    config = super.config // {
      enableParallelBuildingByDefault = true;
    };
  };
  pkgsStrict = nixpkgsFun {
    config = super.config // {
      strictDepsByDefault = true;
    };
  };
  pkgsStructured = nixpkgsFun {
    config = super.config // {
      structuredAttrsByDefault = true;
    };
  };
}
