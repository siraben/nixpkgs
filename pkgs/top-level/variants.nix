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
  # Helper: remove a dependency by pname from a list.
  removeDep = name: lib.filter (d: (d.pname or d.name or "") != name);

  # Helper: append to NIX_CFLAGS_COMPILE in env.
  addCflags = old: flags: (old.env or { }) // {
    NIX_CFLAGS_COMPILE = toString (old.env.NIX_CFLAGS_COMPILE or "") + " " + flags;
  };

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
      # cosmo libc lacks wprintf.
      hello = super'.hello.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          ../development/compilers/cosmocc/hello-no-wprintf.patch
        ];
      });

      ncurses = (super'.ncurses.override { enableStatic = true; }).overrideAttrs (old: {
        env = addCflags old "-include libc/str/unicode.h";
        configureFlags = (old.configureFlags or [ ]) ++ [
          "--without-dlsym"
          "--with-fallbacks=xterm-256color,tmux-256color,screen-256color,vt100,linux,dumb,xterm,xterm-color"
        ];
        # build-cc lacks cosmo's wint_t prelude.
        preConfigure = (old.preConfigure or "") + ''
          export BUILD_CFLAGS="''${BUILD_CFLAGS:+$BUILD_CFLAGS }-include wchar.h"
        '';
        postInstall = (old.postInstall or "") + ''
          if [ -d "$out/lib/.aarch64" ]; then
            for f in "$out/lib"/*.a; do
              [ -L "$f" ] || continue
              ln -svf "$(readlink "$f")" "$out/lib/.aarch64/$(basename "$f")"
            done
          fi
        '';
      });

      gawk = super'.gawk.overrideAttrs (old: {
        configureFlags = (old.configureFlags or [ ]) ++ [ "--disable-extensions" ];
      });

      sqlite = let
        cc = "${super'.stdenv.cc}/bin/${super'.stdenv.cc.targetPrefix}gcc";
        ar = "${super'.stdenv.cc.bintools}/bin/${super'.stdenv.cc.targetPrefix}ar";
      in super'.sqlite.overrideAttrs (old: {
        configureFlags = lib.filter (f: !(lib.hasPrefix "--with-tcl" f)) (old.configureFlags or [ ]) ++ [
          "--disable-tcl" "--disable-load-extension" "--disable-math" "--disable-threadsafe"
        ];
        makeFlags = lib.filter (f: !(lib.hasPrefix "cc=" f) && !(lib.hasPrefix "AR=" f)) (old.makeFlags or [ ]) ++ [
          "cc=${cc}" "AR=${ar}"
        ];
        env = (old.env or { }) // {
          NIX_CFLAGS_COMPILE = toString (old.env.NIX_CFLAGS_COMPILE or "")
            + " -DSQLITE_ENABLE_MATH_FUNCTIONS -DSQLITE_THREADSAFE=0";
          NIX_LDFLAGS = toString (old.env.NIX_LDFLAGS or "") + " -lm";
        };
        nativeBuildInputs = removeDep "tcl" (old.nativeBuildInputs or [ ]);
        buildInputs = removeDep "tcl" (old.buildInputs or [ ]);
        preConfigure = (old.preConfigure or "") + ''
          export CC="${cc}" AR="${ar}"
        '';
      });

      tcl = super'.tcl.overrideAttrs (old: {
        env = addCflags old "-UPACKAGE_STRING -DPACKAGE_STRING='\"tcl-8.6\"'";
      });

      tzdata = super'.tzdata.overrideAttrs (old: {
        makeFlags = (old.makeFlags or [ ]) ++ [
          "CFLAGS+=-DHAVE_MEMPCPY=1" "CFLAGS+=-DHAVE_ISSETUGID=1"
        ];
      });

      jq = (super'.jq.override { onigurumaSupport = false; }).overrideAttrs (old: {
        postConfigure = (old.postConfigure or "") + ''
          sed -i 's/-DPACKAGE_STRING=[^ ]*\\ [^ ]*//' Makefile
        '';
        doInstallCheck = false;
      });

      lua = super'.lua.override { staticOnly = true; };

      openssl = super'.openssl.overrideAttrs (old: {
        configureFlags = (old.configureFlags or [ ]) ++ [
          "no-shared" "no-ktls" "no-asm" "no-dso" "no-engine"
        ];
      });

      curl = (super'.curl.override {
        zstdSupport = false; gssSupport = false; http3Support = false;
        http2Support = false; brotliSupport = false; idnSupport = false;
        pslSupport = false; scpSupport = false; opensslSupport = false;
        zlibSupport = false;
      }).overrideAttrs (old: {
        configureFlags = (old.configureFlags or [ ]) ++ [ "--without-librtmp" ];
      });

      # Both use cmake and need static-only.
      nghttp3 = super'.nghttp3.overrideAttrs (old: {
        cmakeFlags = (old.cmakeFlags or [ ]) ++ [ "-DENABLE_SHARED_LIB=OFF" "-DENABLE_STATIC_LIB=ON" ];
      });
      ngtcp2 = super'.ngtcp2.overrideAttrs (old: {
        cmakeFlags = (old.cmakeFlags or [ ]) ++ [ "-DENABLE_SHARED_LIB=OFF" "-DENABLE_STATIC_LIB=ON" ];
      });

      flex = super'.flex.overrideAttrs (old: {
        nativeBuildInputs = removeDep "autoreconf-hook" (old.nativeBuildInputs or [ ]);
        patches = lib.filter (p: !(lib.hasInfix "glibc-2.26" (builtins.toString p))) (old.patches or [ ]);
        preConfigure = (old.preConfigure or "") + ''
          export NIX_LDFLAGS_x86_64_unknown_linux_gnu="$(echo "$NIX_LDFLAGS_x86_64_unknown_linux_gnu" | tr ' ' '\n' | grep -v binutils | tr '\n' ' ')"
          export PATH="$(echo "$PATH" | tr ':' '\n' | grep -v 'gcc-wrapper\|binutils-wrapper' | tr '\n' ':')"
        '';
      });

      bison = super'.bison.overrideAttrs (old: {
        env = addCflags old "-include libc/nexgen32e/ffs.h";
      });

      gnum4 = super'.gnum4.overrideAttrs (old: {
        # tests/ builds gnulib code as part of `make all`.
        postPatch = (old.postPatch or "") + ''
          sed -i '/^SUBDIRS/s/ tests\b//' Makefile.in
        '';
        env = addCflags old "-DHAVE_SAME_LONG_DOUBLE_AS_DOUBLE=1";
      });

      bc = super'.bc.overrideAttrs (old: {
        buildInputs = removeDep "flex" (old.buildInputs or [ ]);
        depsBuildBuild = [ ];
        nativeBuildInputs = removeDep "autoreconf-hook" (old.nativeBuildInputs or [ ]);
      });

      coreutils = (super'.coreutils.override {
        aclSupport = false; attrSupport = false; selinuxSupport = false;
        gmpSupport = false; withOpenssl = false; singleBinary = false;
      }).overrideAttrs (old: {
        configureFlags = lib.filter (f:
          !(lib.hasPrefix "--enable-install-program" f) &&
          !(lib.hasPrefix "--with-selinux" f)
        ) (old.configureFlags or [ ]) ++ [
          "--without-selinux" "--disable-acl" "--disable-xattr"
          "--enable-no-install-program=stdbuf"
        ];
        postPatch = (old.postPatch or "") + ''
          cp ${../development/compilers/cosmocc/fadvise.h} lib/fadvise.h
          cat > lib/fadvise.c <<'EOF'
          #include <config.h>
          #include "fadvise.h"
          EOF
          # O_* flags are extern const in cosmo — hardcode private flags.
          sed -i '/^#define FFS_MASK/,/^static_assert.*O_SEEK_BYTES/c\
          #define O_FULLBLOCK  (1 << 25)\
          #define O_NOCACHE    (1 << 26)\
          #define O_COUNT_BYTES (1 << 27)\
          #define O_SKIP_BYTES  (1 << 28)\
          #define O_SEEK_BYTES  (1 << 29)' src/dd.c
          # PIPE_BUF is extern const in cosmo.
          sed -i 's/enum { FACTOR_PIPE_BUF = PIPE_BUF };/enum { FACTOR_PIPE_BUF = 4096 };/' src/factor.c
          # Symbol conflict with cosmo's touch(const char*, unsigned).
          sed -i 's/\btouch\b/coreutils_touch/g' src/touch.c
        '';
        env = addCflags old "-Wno-error";
        doCheck = false;
        separateDebugInfo = false;
      });

      diffutils = (super'.diffutils.override { coreutils = null; }).overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          sed -i 's/ELOOP$/40/' src/diff.c
          sed -i '/^SUBDIRS/s/ man / /' Makefile.in
        '';
      });

      gnupatch = super'.gnupatch.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          sed -i 's/enum { DIRFD_INVALID = -1 - (AT_FDCWD == -1) };/enum { DIRFD_INVALID = -1 - (-100 == -1) };/' src/safe.h
        '';
      });

      findutils = super'.findutils.overrideAttrs (old: {
        buildInputs = removeDep "coreutils" (old.buildInputs or [ ]);
        postPatch = (old.postPatch or "") + ''
          sed -i 's/(void) __STDC_LIMIT_MACROS;/(void) 0;/' xargs/xargs.c
        '';
        configureFlags = lib.filter (f: !(lib.hasPrefix "SORT=" f)) (old.configureFlags or [ ]) ++ [ "SORT=sort" ];
      });

      vim = super'.vim.overrideAttrs (old: {
        configureFlags = (old.configureFlags or [ ]) ++ [
          "--disable-darwin" "vim_cv_uname_output=Linux" "vim_cv_timer_create=no"
        ];
      });

      gnutar = (super'.gnutar.override { aclSupport = false; }).overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          sed -i 's/enum { IMPOSTOR_ERRNO = ENOENT };/#define IMPOSTOR_ERRNO ENOENT/' src/create.c
        '';
      });

      xz = super'.xz.overrideAttrs (old: {
        configureFlags = (old.configureFlags or [ ]) ++ [ "--enable-sandbox=no" ];
      });

      zstd = (super'.zstd.override { static = true; }).overrideAttrs (old: {
        # CMake can't execve APE ar on macOS; use plain Makefile build.
        nativeBuildInputs = removeDep "cmake" (old.nativeBuildInputs or [ ]);
        dontUseCmakeConfigure = true;
        cmakeFlags = [ ]; cmakeDir = null; dontUseCmakeBuildDir = false;
        preConfigure = "";
        makeFlags = [
          "PREFIX=$(out)" "BINDIR=$(bin)/bin" "INCLUDEDIR=$(dev)/include"
          "MANDIR=$(man)/share/man" "LIBDIR=$(out)/lib" "PKGCONFIGDIR=$(dev)/lib/pkgconfig"
        ];
        buildFlags = [ "zstd-release" ];
        buildPhase = ''
          runHook preBuild
          make -C lib libzstd.a $makeFlags
          make -C programs zstd-release $makeFlags
          runHook postBuild
        '';
        installPhase = ''
          runHook preInstall
          make -C lib install-static install-includes install-pc $makeFlags
          make -C programs install $makeFlags
          runHook postInstall
        '';
        preInstall = ''
          mkdir -p $bin/bin $dev/include $dev/lib/pkgconfig $out/lib $man/share/man/man1
        '';
      });

      gnugrep = (super'.gnugrep.override { runtimeShellPackage = null; }).overrideAttrs (old: {
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
    then
      # On x86_64-linux, reuse hostPlatform so build == host and APE binaries
      # can execute during configure tests.
      stdenv.hostPlatform // { useCosmopolitan = true; }
    else if stdenv.hostPlatform.isAarch64
    then
      # On aarch64 (Linux or Darwin), produce aarch64 cosmo binaries.
      { config = "aarch64-unknown-linux-gnu"; useCosmopolitan = true; cosmoArch = "aarch64"; }
    else
      # Other platforms: cross-compile targeting x86_64.
      { config = "x86_64-unknown-linux-gnu"; useCosmopolitan = true; }
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
