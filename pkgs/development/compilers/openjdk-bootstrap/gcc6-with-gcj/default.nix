{
  lib,
  stdenv,
  fetchurl,
  bison,
  binutils,
  flex,
  gawk,
  gmp,
  isl_0_20,
  libmpc,
  mpfr,
  texinfo,
  zip,
  zlib,
}:

# Last GCC with the gcj Java front-end (removed in GCC 7). Used solely
# to AOT-compile the Eclipse Compiler for Java (ECJ) jar into a native
# `javac` for IcedTea's OpenJDK 7 bootstrap.

let
  version = "6.5.0";
  ecjVersion = "4.9";

  # Pure-Java jar admitted as source per the bootstrappable.org Java
  # convention. GCC 6 requires it under the exact name `ecj.jar`.
  ecjJar = fetchurl {
    url = "https://sourceware.org/pub/java/ecj-${ecjVersion}.jar";
    hash = "sha256-lQbnW4YveCIT32GvZzOOt6I8Nf9CXTKK/8ZVhUd9NM0=";
  };
in

stdenv.mkDerivation {
  pname = "gcc6-with-gcj";
  inherit version;

  src = fetchurl {
    url = "https://ftpmirror.gnu.org/gnu/gcc/gcc-${version}/gcc-${version}.tar.xz";
    hash = "sha256-fvF5bOSX6JR5GDcCY1sUu3pGtTJJIJpeD5mb6/R0CUU=";
  };

  patches = [
    ./patches/fix-cxxflags-passing.patch
    ./patches/fix-gcj-arm-thumb.patch
    ./patches/fix-gcj-stdgnu14-link.patch
    ./patches/0017-pr93402.patch
    ./patches/isl-0.22.patch
  ];

  postPatch = ''
    cp ${ecjJar} ecj.jar
  '';

  nativeBuildInputs = [
    bison
    flex
    gawk
    texinfo
    zip
  ];

  # gcj/g++ shells out to as and ld; propagate so consumers needn't redeclare.
  propagatedBuildInputs = [ binutils ];

  buildInputs = [
    gmp
    isl_0_20
    libmpc
    mpfr
    zlib
  ];

  hardeningDisable = [
    "format"
    "fortify"
    "fortify3"
    "stackprotector"
    "pic"
  ];

  preConfigure = ''
    mkdir -p build
    cd build
    configureScript=../configure
  '';

  env = {
    CFLAGS = "-O2 -Wall -pipe -Wno-error=format-security";
    CXXFLAGS = "-O2 -Wall -pipe -Wno-error=format-security";
    CPPFLAGS = "-O2 -Wall -pipe -Wno-error=format-security";
    # Point the target-side libgcc/libjava builds at glibc's CRT and
    # zlib; the Nix sandbox has no /usr/lib for them to find.
    LDFLAGS_FOR_TARGET = "-B${lib.getLib stdenv.cc.libc}/lib -L${lib.getLib stdenv.cc.libc}/lib -L${zlib.out}/lib -L${placeholder "out"}/lib/gcc/x86_64-pc-linux-gnu/6.5.0";
    LIBRARY_PATH = "${lib.getLib stdenv.cc.libc}/lib:${zlib.out}/lib:${placeholder "out"}/lib/gcc/x86_64-pc-linux-gnu/6.5.0";
    CPATH = "${zlib.dev}/include";
    CPLUS_INCLUDE_PATH = "${zlib.dev}/include";
  };

  configurePlatforms = [ ];

  configureFlags = [
    "--program-suffix=-6.5"
    "--enable-languages=c,c++,java"
    # 3-stage bootstrap fails on glibc-2.40+ noexcept attributes
    # triggering -Werror=pedantic in old libiberty headers. 1-stage is
    # sufficient for a bootstrap seed.
    "--disable-bootstrap"
    "--enable-host-shared"
    "--enable-shared"
    "--enable-threads=posix"
    "--enable-tls"
    "--enable-default-pie"
    "--enable-default-ssp"
    "--enable-initfini-array"
    "--enable-version-specific-runtime-libs"
    "--enable-gnu-indirect-function"
    "--enable-gnu-unique-object"
    "--disable-multilib"
    "--disable-libsanitizer"
    "--disable-libatomic"
    "--disable-nls"
    "--disable-werror"
    "--with-system-zlib"
    "--with-linker-hash-style=gnu"
    "--with-jvm-root-dir=${placeholder "out"}/lib/jvm/java-1.5-gcj"
    "--with-build-sysroot=/"
    "--with-native-system-header-dir=${lib.getDev stdenv.cc.libc}/include"
  ];

  enableParallelBuilding = true;

  # libtool's relink-during-install for libjava can't find -lgcj because
  # its env doesn't inherit LDFLAGS_FOR_TARGET. Files install correctly;
  # only the RPATH fix-up exits non-zero. Continue with -k.
  installPhase = ''
    runHook preInstall
    make -k install -j$NIX_BUILD_CORES || true
    runHook postInstall
  '';

  postInstall = ''
    find $out -name '*.la' -delete

    for f in gcj-6.5 gij-6.5 gjar-6.5; do
      test -x $out/bin/$f || { echo "ERROR: $f missing"; exit 1; }
    done
    test -e $out/lib/gcc/x86_64-pc-linux-gnu/6.5.0/libgcj.so \
      || test -e $out/lib/libgcj.so \
      || { echo "ERROR: libgcj.so missing"; exit 1; }

    rm -rf $out/share/info $out/share/locale
  '';

  passthru = {
    inherit ecjJar;
    isFromBootstrapFiles = false;
  };

  meta = {
    description = "GCC 6.5.0 with the gcj Java front-end";
    homepage = "https://gcc.gnu.org/";
    license = lib.licenses.gpl3Plus;
    platforms = [
      "x86_64-linux"
      "i686-linux"
    ];
  };
}
