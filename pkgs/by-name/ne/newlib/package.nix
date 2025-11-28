{
  stdenvNoLibc,
  fetchurl,
  buildPackages,
  lib,
  fetchpatch,
  texinfo,
  # "newlib-nano" is what the official ARM embedded toolchain calls this build
  # configuration that prioritizes low space usage. We include it as a preset
  # for embedded projects striving for a similar configuration.
  nanoizeNewlib ? false,
}:

let
  targetConfig = stdenvNoLibc.targetPlatform.config;
  isMmix = stdenvNoLibc.targetPlatform.parsed.cpu.name == "mmix";
in
stdenvNoLibc.mkDerivation (finalAttrs: {
  pname = "newlib";
  version = "4.5.0.20241231";

  src = fetchurl {
    url = "ftp://sourceware.org/pub/newlib/newlib-${finalAttrs.version}.tar.gz";
    sha256 = "sha256-M/EmBeAFSWWZbCXBOCs+RjsK+ReZAB9buMBjDy7IyFI=";
  };

  patches = [
    (fetchpatch {
      name = "0001-newlib-Fix-mips-libgloss-support.patch";
      url = "https://sourceware.org/git/?p=newlib-cygwin.git;a=patch;h=8a8fb570d7c5310a03a34b3dd6f9f8bb35ee9f40";
      hash = "sha256-hWS/X0jf/ZFXIR39NvNDVhkR8F81k9UWpsqDhZFxO5o=";
    })
  ]
  ++ lib.optionals nanoizeNewlib [
    # https://bugs.gentoo.org/723756
    (fetchpatch {
      name = "newlib-3.3.0-no-nano-cxx.patch";
      url = "https://gitweb.gentoo.org/repo/gentoo.git/plain/sys-libs/newlib/files/newlib-3.3.0-no-nano-cxx.patch?id=9ee5a1cd6f8da6d084b93b3dbd2e8022a147cfbf";
      sha256 = "sha256-S3mf7vwrzSMWZIGE+d61UDH+/SK/ao1hTPee1sElgco=";
    })
  ]
  ++ lib.optionals isMmix [
    # Add getrlimit and getprogname support for MMIX/mmixware
    ./patches/newlib-mmix-rlimit.patch
    ./patches/newlib-mmix-dirent-header.patch
    ./patches/newlib-mmix-glob-flags.patch
    ./patches/newlib-mmix-termios.patch
    ./patches/newlib-mmix-signal-handlers.patch
  ];

  depsBuildBuild = [
    buildPackages.stdenv.cc
    texinfo # for makeinfo
  ];

  # newlib expects CC to build for build platform, not host platform
  preConfigure = ''
    export CC=cc
  ''
  +
    # newlib tries to disable itself when building for Linux *except*
    # when native-compiling.  Unfortunately the check for "is cross
    # compiling" was written when newlib was part of GCC and newlib
    # was built along with GCC (therefore newlib was built to execute
    # on the targetPlatform, not the hostPlatform).  Unfortunately
    # when newlib was extracted from GCC, this "is cross compiling"
    # logic was not fixed.  So we must disable it.
    ''
      substituteInPlace configure --replace 'noconfigdirs target-newlib target-libgloss' 'noconfigdirs'
      substituteInPlace configure --replace 'cross_only="target-libgloss target-newlib' 'cross_only="'
    '';

  configurePlatforms = [
    "build"
    "target"
  ];
  # flags copied from https://community.arm.com/support-forums/f/compilers-and-libraries-forum/53310/gcc-arm-none-eabi-what-were-the-newlib-compilation-options
  # sort alphabetically
  configureFlags = [
    "--with-newlib"

    # The newlib configury uses `host` to refer to the platform
    # which is being used to compile newlib.  Ugh.  It does this
    # because of its history: newlib used to be distributed with and
    # built as part of gcc.
    #
    # To prevent nixpkgs from going insane, this package presents the
    # "normal" view to the outside world: the binaries in $out will
    # execute on `stdenv.hostPlatform`.  We then fool newlib's build
    # process into doing the right thing.
    "--host=${stdenvNoLibc.targetPlatform.config}"

  ]
  ++ (
    if !nanoizeNewlib then
      (
        lib.optional (!isMmix) "--disable-newlib-supplied-syscalls"
        ++ [
          "--disable-nls"
          "--enable-newlib-io-c99-formats"
          "--enable-newlib-io-long-long"
          "--enable-newlib-reent-check-verify"
          "--enable-newlib-register-fini"
          "--enable-newlib-retargetable-locking"
        ]
      )
    else
      (
        lib.optional (!isMmix) "--disable-newlib-supplied-syscalls"
        ++ [
          "--disable-newlib-fseek-optimization"
          "--disable-newlib-fvwrite-in-streamio"
          "--disable-newlib-unbuf-stream-opt"
          "--disable-newlib-wide-orient"
          "--disable-nls"
          "--enable-lite-exit"
          "--enable-newlib-global-atexit"
          "--enable-newlib-nano-formatted-io"
          "--enable-newlib-nano-malloc"
          "--enable-newlib-reent-check-verify"
          "--enable-newlib-reent-small"
          "--enable-newlib-retargetable-locking"
        ]
      )
  );

  enableParallelBuilding = true;
  dontDisableStatic = true;

  # apply necessary nano changes from https://developer.arm.com/-/media/Files/downloads/gnu/12.2.rel1/manifest/copy_nano_libraries.sh?rev=4c50be6ccb9c4205a5262a3925317073&hash=1375A7B0A1CD0DB9B9EB0D2B574ADF66
  postInstall =
    lib.optionalString nanoizeNewlib ''
      mkdir -p $out${finalAttrs.passthru.incdir}/newlib-nano
      cp $out${finalAttrs.passthru.incdir}/newlib.h $out${finalAttrs.passthru.incdir}/newlib-nano/

      (
        cd $out${finalAttrs.passthru.libdir}

        for f in librdimon.a libc.a libm.a libg.a libgloss.a; do
          # Some libraries are only available for specific architectures.
          # For example, librdimon.a is only available on ARM.
          if [ -f "$f" ]; then
            dst="''${f%%\.a}_nano.a"
            >&2 echo "$f -> $dst"
            cp "$f" "$dst"
          fi
        done
      )
    ''
    + lib.optionalString isMmix ''
      targetLib="$out${finalAttrs.passthru.libdir}"
      target="${targetConfig}"
      cc="$target-cc"
      ar="$target-ar"
      ranlib="$target-ranlib"
      buildRoot=$PWD
      sysDir="$buildRoot/newlib/libc/sys/mmixware"
      targInc="$buildRoot/$target/newlib/targ-include"
      sysInc="$buildRoot/newlib/libc/include"
      mkdir -p mmix-extra-objs
      for src in getprogname.c getrlimit.c dirent.c mknod.c signal.c termios.c; do
        "$cc" -Os -ffreestanding -I"$sysInc" -I"$targInc" -I"$sysDir/sys" -c "$sysDir/$src" -o "mmix-extra-objs/''${src%.c}.o"
        "$ar" rcs "$targetLib/libc.a" "mmix-extra-objs/''${src%.c}.o"
      done
      "$ranlib" "$targetLib/libc.a"
    ''
    + ''[ "$(find $out -type f | wc -l)" -gt 0 ] || (echo '$out is empty' 1>&2 && exit 1)'';

  passthru = {
    incdir = "/${stdenvNoLibc.targetPlatform.config}/include";
    libdir = "/${stdenvNoLibc.targetPlatform.config}/lib";
  };

  meta = with lib; {
    description = "C library intended for use on embedded systems";
    homepage = "https://sourceware.org/newlib/";
    # arch has "bsd" while gentoo has "NEWLIB LIBGLOSS GPL-2" while COPYING has "gpl2"
    # there are 5 copying files in total
    # COPYING
    # COPYING.LIB
    # COPYING.LIBGLOSS
    # COPYING.NEWLIB
    # COPYING3
    license = licenses.gpl2Plus;
  };
})
