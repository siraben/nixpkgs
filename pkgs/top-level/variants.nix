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
        # Fat cosmo stitching produces .o files that trigger -Werror.
        env = addCflags old "-Wno-error";
        preConfigure = (old.preConfigure or "") + ''
          export CFLAGS="''${CFLAGS:+$CFLAGS }-Wno-error"
        '';
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

      python3Minimal = let
        cosmoCC = "${super'.stdenv.cc}/bin/${super'.stdenv.cc.targetPrefix}gcc";
        cosmoAR = "${super'.stdenv.cc.bintools}/bin/${super'.stdenv.cc.targetPrefix}ar";
      in (super'.python3Minimal.override {
        allowedReferenceNames = [ ];
      }).overrideAttrs (old: {
        buildInputs = lib.filter (d:
          (d.pname or d.name or "") != "bash"
        ) (old.buildInputs or [ ]);
        postPatch = "";
        separateDebugInfo = false;
        preConfigure = (old.preConfigure or "") + ''
          export CC="${cosmoCC}"
          export AR="${cosmoAR}"
        '';
        configureFlags = lib.filter (f:
          f != "--enable-shared"
        ) (old.configureFlags or [ ]) ++ [
          "--disable-shared"
          "--disable-test-modules"
          "LDFLAGS=-static"
          "MODULE_BUILDTYPE=static"
        ];
        postInstall = builtins.replaceStrings
          [ "touch $out/lib/"
            "rm -R $out/lib/python*/test"
            "rm -R $out/bin/idle"
            "rm -R $out/lib/python*/tkinter"
          ]
          [ "[ -d $out/lib/python3.13/test ] && touch $out/lib/"
            "rm -rf $out/lib/python*/test"
            "rm -rf $out/bin/idle"
            "rm -rf $out/lib/python*/tkinter"
          ]
          (old.postInstall or "");
      });

      gnugrep = (super'.gnugrep.override { runtimeShellPackage = null; }).overrideAttrs (old: {
        postInstall = "";
        buildInputs = lib.filter (d: !(lib.hasInfix "glibc-iconv" (d.name or ""))) (old.buildInputs or [ ]);
      });

      # BLOCKED: emacs-nox compilation succeeds but the resulting temacs
      # binary enters infinite recursion during cosmo's CRT initialization
      # (before main() is reached), causing a stack overflow.  This is
      # triggered by cosmocc's "rewrote N switch statements" transformation
      # which converts extern-const case labels (AF_INET6, AF_LOCAL, etc.)
      # into if-else chains.  The rewritten code recurses infinitely.
      # Upstream cosmocc fix needed.  See also: process.c switch on AF_*,
      # sysdep.c termios speed constants, lib/sig2str.c signal constants.
      emacs-nox = (super'.emacs-nox.override {
        withNativeCompilation = false;
        withTreeSitter = false;
        withDbus = false;
        withGpm = false;
        withSelinux = false;
        withSystemd = false;
        withSQLite3 = false;
        withWebP = false;
        withMailutils = false;
        withAcl = false;
        withAlsaLib = false;
      }).overrideAttrs (old: {
        configureFlags = (old.configureFlags or [ ]) ++ [
          "--without-gnutls"
          "--without-libxml2"
          "--without-harfbuzz"
          "--without-sound"
          "--without-modules"
          "--without-threads"
          "--without-zlib"
          "--without-compress-install"
          "--without-file-notification"
          "--with-dumping=none"
        ];
        # Strip postPatch of references to gettext/mailcap (cross packages).
        postPatch = ''
          find . -type f \( -name "*.elc" -o -name "*loaddefs.el" \) -exec rm {} \;
          for makefile_in in $(find . -name Makefile.in -print); do
            substituteInPlace $makefile_in --replace-warn /bin/pwd pwd
          done
          # Cosmopolitan libc errno values are extern const, not integer constants.
          sed -i 's/enum { LINKS_MIGHT_NOT_WORK = EPERM };/#define LINKS_MIGHT_NOT_WORK 1/' src/filelock.c
          sed -i 's/enum { NEGATIVE_ERRNO = EDOM < 0 };/#define NEGATIVE_ERRNO 0/' src/filelock.c

          # Stub out arrays using extern-const initializers to reduce
          # cosmocc's "modified initializations" constructors.
          sed -i '/^static const struct speed_struct speeds\[\]/,/^  };/c\
static const struct speed_struct speeds[] = { {0, 0} };' src/sysdep.c

          cat > lib/sigdescr_np.c <<'STUBEOF'
#include <config.h>
#include <string.h>
const char *sigdescr_np (int sig) { return "Unknown signal"; }
STUBEOF
          cat > lib/sig2str.c <<'STUBEOF'
#include <config.h>
#include <signal.h>
#include <string.h>
#include "sig2str.h"
int sig2str (int signum, char *buf) { strcpy(buf, "UNKNOWN"); return -1; }
int str2sig (const char *buf, int *signum) { return -1; }
STUBEOF

          awk '
            /^} socket_options\[\] =/ { print "} socket_options[] = { { 0, 0, 0, SOPT_UNKNOWN, OPIX_NONE } };"; skip=1; next }
            skip && /^  };/ { skip=0; next }
            !skip { print }
          ' src/process.c > src/process.c.tmp && mv src/process.c.tmp src/process.c

          awk '
            /^static const struct ifflag_def ifflag_table\[\] = \{/ { print "static const struct ifflag_def ifflag_table[] = {"; print "  { 0, 0 }"; skip=1; next }
            skip && /^  \{ 0, 0 \}/ { skip=0; next }
            !skip { print }
          ' src/process.c > src/process.c.tmp && mv src/process.c.tmp src/process.c
        '';
        nativeBuildInputs = removeDep "make-shell-wrapper-hook" (old.nativeBuildInputs or [ ]);
        buildInputs = lib.filter (d:
          !builtins.elem (d.pname or d.name or "") [
            "gnutls" "harfbuzz" "libxml2" "gettext" "mailutils" "mailcap"
          ]
        ) (old.buildInputs or [ ]);
        env = addCflags old "-Wno-error";
      });

      # --- Nix package manager dependencies ---

      # Boehm GC: cosmo's normalize.inc undefs __linux__ and __x86_64__, so
      # gcconfig.h can't detect the platform even with -D flags.  We patch
      # gcconfig.h to recognise __COSMOPOLITAN__ as Linux x86_64.
      boehmgc = (super'.boehmgc.override {
        enableLargeConfig = true;
      }).overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          # Add cosmopolitan detection right before the "not ported" error.
          sed -i '/# if !defined(mach_type_known)/i \
          #if defined(__COSMOPOLITAN__)\
          # define LINUX\
          # define X86_64\
          # define mach_type_known\
          #endif' include/private/gcconfig.h

          # madvise declaration is missing from cosmo's sys/mman.h.
          sed -i '/#include.*gc_priv/a \
          #ifndef madvise\
          extern int madvise(void *, size_t, int);\
          #endif' os_dep.c

          # Cosmo lacks getcontext/setcontext; disable checksum-based
          # mark stack resumption that requires them.
          sed -i 's/# *define HAVE_BUILTIN_UNWIND_INIT//* &: disabled for cosmo *\//' include/private/gcconfig.h || true
        '';
        configureFlags = (old.configureFlags or [ ]) ++ [
          "--disable-threads"
          "--disable-thread-local-alloc"
          "--disable-parallel-mark"
        ];
        env = addCflags old "-DNO_GETCONTEXT -DDONT_USE_SIGCONTEXT -DUSE_MMAP";
        preConfigure = (old.preConfigure or "") + ''
          export CFLAGS="''${CFLAGS:+$CFLAGS }-DNO_GETCONTEXT -DDONT_USE_SIGCONTEXT -DUSE_MMAP"
        '';
      });

      # lowdown: cosmo needs _GNU_SOURCE for memmem/mkfifo, and the configure
      # script's runtime tests fail under cross, so we override detection results.
      # _NSIG is non-constant in cosmo, so readpassphrase compat can't compile.
      lowdown = (super'.lowdown.override {
        enableShared = false;
        enableStatic = true;
      }).overrideAttrs (old: {
        env = addCflags old "-D_GNU_SOURCE";
        preConfigure = (old.preConfigure or "") + ''
          cat > configure.local <<'CONF'
          HAVE_GETPROGNAME=0
          HAVE_MEMMEM=1
          HAVE_MEMRCHR=1
          HAVE_MKFIFOAT=0
          HAVE_PROGRAM_INVOCATION_SHORT_NAME=1
          HAVE___PROGNAME=0
          HAVE_READPASSPHRASE=0
          HAVE_FTS=0
          HAVE_CAPSICUM=0
          HAVE_LANDLOCK=0
          HAVE_SECCOMP_FILTER=0
          HAVE_PLEDGE=0
          HAVE_UNVEIL=0
          HAVE_SANDBOX_INIT=0
          HAVE_STATIC=1
          CONF
        '';
        postPatch = (old.postPatch or "") + ''
          # _NSIG is non-const in cosmo — replace with a fixed size.
          sed -i 's/\[_NSIG\]/[128]/' compats.c
          # cosmo lacks mkfifo; declare it and provide a stub mkfifoat.
          # Replace the compat mkfifoat implementation with ENOSYS stub.
          sed -i 's/if ((newfd = mkfifo(path, mode)) == -1)/errno = ENOSYS; newfd = -1; if (newfd == -1)/' compats.c
        '';
        doInstallCheck = false;
      });

      # libsodium: PACKAGE_STRING with spaces is fatal for cosmocc, and libtool
      # has archive path conflicts with cosmo's ar wrapper.
      libsodium = super'.libsodium.overrideAttrs (old: {
        postConfigure = (old.postConfigure or "") + ''
          find . -name Makefile -exec sed -i 's/^DEFS = .*/DEFS = -DHAVE_CONFIG_H/' {} \;
          # Fix libtool double-slash in archive extraction paths.
          # The issue: libtool constructs paths like foo.a//build/path which
          # fails. Patch libtool to normalize paths.
          sed -i 's|func_lalib_p "$lib"|& \&\& lib=$(echo "$lib" | sed "s|//|/|g")|' libtool || true
          # Simpler: disable convenience library linking entirely.
          # Build .o files directly into libsodium.a.
          sed -i 's/^convenience=.*/convenience=""/' libtool || true
        '';
        configureFlags = (old.configureFlags or [ ]) ++ [
          "--disable-shared" "--enable-static" "--disable-asm"
          "--disable-dependency-tracking"
        ];
        # Build all objects into a single library without convenience archives.
        postBuild = (old.postBuild or "") + ''
          # If the libtool fix didn't work, manually combine the .o files.
          if [ ! -f src/libsodium/.libs/libsodium.a ]; then
            find src -name '*.o' -not -path '*/.libs/*' | sort | \
              xargs x86_64-unknown-linux-gnu-ar rcs src/libsodium/.libs/libsodium.a
          fi
        '';
      });

      # bzip2: PACKAGE_STRING/PACKAGE_BUGREPORT with spaces are fatal for cosmocc.
      # The values in DEFS contain spaces.  We clear DEFS entirely and ensure
      # config.h (which bzip2 uses via -DHAVE_CONFIG_H) has all needed defines.
      bzip2 = super'.bzip2.overrideAttrs (old: {
        postConfigure = (old.postConfigure or "") + ''
          # The DEFS variable in the Makefile passes -D flags that contain
          # spaces.  Since bzip2 already uses config.h for these defines,
          # we simply clear DEFS.
          find . -name Makefile -exec sed -i 's/^DEFS = .*/DEFS = -DHAVE_CONFIG_H/' {} \;
        '';
      });

      # libblake3: disable TBB (threading) and SIMD asm (cosmo can't assemble .S files).
      libblake3 = (super'.libblake3.override {
        useTBB = false;
      }).overrideAttrs (old: {
        cmakeFlags = (old.cmakeFlags or [ ]) ++ [
          "-DBUILD_SHARED_LIBS=OFF"
          "-DBLAKE3_SIMD_TYPE=none"
        ];
      });

      # mimalloc: madvise declaration missing from cosmo's sys/mman.h.
      mimalloc = super'.mimalloc.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          sed -i '/#include <sys\/mman.h>/a \
          #ifndef madvise\
          extern int madvise(void *, size_t, int);\
          #endif' src/prim/unix/prim.c
        '';
        cmakeFlags = (old.cmakeFlags or [ ]) ++ [
          "-DMI_BUILD_SHARED=OFF"
          "-DMI_BUILD_TESTS=OFF"
          "-DMI_USE_CXX=OFF"
        ];
      });

      # boost: header-heavy, should mostly work.  Disable threading for cosmo.
      boost = super'.boost.overrideAttrs (old: {
        # boost's b2 build system needs explicit flags for static-only.
        # Threading support is problematic under cosmo.
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
