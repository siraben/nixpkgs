{
  lib,
  stdenv,
  fetchurl,
  boot-jdk,
  autoconf,
  automake,
  pkg-config,
  zip,
  unzip,
  cups,
  freetype,
  fontconfig,
  alsa-lib,
  libx11,
  libice,
  libxt,
  libxtst,
  libxi,
  libxext,
  libxrender,
  libxrandr,
  libxcursor,
  libxinerama,
  libxcomposite,
  libxft,
  libxslt,
  libxml2,
  libpng,
  xorgproto,
  gtk2,
  cairo,
  pango,
  gdk-pixbuf,
  harfbuzz,
  fribidi,
  lcms2,
  libjpeg_turbo,
  libffi,
  giflib,
  krb5,
  expat,
  zlib,
  perl,
  attr,
  file,
  wget,
  which,
  net-tools,
  cpio,
  procps,
}:

# IcedTea 3.35.0 driving the OpenJDK 8 build (jdk8u452-b09).
#
# Boots from openjdk7-icedtea on real HotSpot, so build time drops
# from ~6-10 h (gij interpreted) to ~90-120 min.

let
  version = "3.35.0";

  drop = name: hash: fetchurl {
    url = "https://icedtea.classpath.org/download/drops/icedtea8/${name}";
    inherit hash;
  };
  openjdkGit = fetchurl {
    url = "https://icedtea.classpath.org/download/drops/icedtea8/${version}/openjdk-git.tar.xz";
    hash = "sha512-pXCBov381//yID2C1cTt1uP9ey/P1e9UcRcwc7k711399nsgss7ObEs6JJ+RG6dPvfXgjFPvVQHPFgDFQgjXzg==";
  };
  hotspotDrop = drop "hotspot.tar.xz"
    "sha512-XI6DnS10sDCPRo2HY6aasGkg9DuSZZu6x29TtI2Dzo1wcKCRyjbfmWKTZPyNBbgnLnwS0EYJuWnV6NtqzmkI3w==";
in

stdenv.mkDerivation {
  pname = "openjdk8-icedtea";
  inherit version;

  src = fetchurl {
    url = "https://icedtea.classpath.org/download/source/icedtea-${version}.tar.xz";
    hash = "sha512-Ppl8jSqkFPqxkpwN2P9YaVC8ZTpXS5KeXDS24BvqGvklmyyVSOkYfcKy4+A1j/6ZHEYM/3ou/DPHqmamgSwIBA==";
  };

  postPatch = ''
    # Drop /bin/echo / /bin/pwd from IcedTea's framework Makefiles.
    find . -maxdepth 3 -type f \( -name 'Makefile*' -o -name '*.gmk' -o -name '*.am' -o -name '*.in' -o -name '*.sh' \) \
      | xargs -r sed -i \
          -e 's|/bin/echo|echo|g' \
          -e 's|/bin/pwd|pwd|g' \
          || true
  '';

  nativeBuildInputs = [
    autoconf
    automake
    pkg-config
    zip
    unzip
    perl
    file
    wget
    which
    net-tools
    cpio
    procps
  ];

  buildInputs = [
    cups
    freetype
    fontconfig
    alsa-lib
    libx11
    libice
    libxt
    libxtst
    libxi
    libxext
    libxrender
    libxrandr
    libxcursor
    libxinerama
    libxcomposite
    libxft
    libxslt
    libxml2
    libpng
    gtk2
    cairo
    pango
    gdk-pixbuf
    harfbuzz
    fribidi
    lcms2
    libjpeg_turbo
    libffi
    giflib
    krb5
    expat
    zlib
    attr
  ];

  enableParallelBuilding = true;

  hardeningDisable = [
    "format"
    "fortify"
    "fortify3"
    "stackprotector"
    "pic"
  ];

  env = {
    CFLAGS = "-Wno-int-conversion -Wno-incompatible-pointer-types";
  };

  preConfigure = ''
    mkdir -p icedtea-drops
    drops_abs=$(realpath icedtea-drops)
    cp ${openjdkGit}    "$drops_abs/openjdk-git.tar.xz"
    cp ${hotspotDrop}   "$drops_abs/hotspot.tar.xz"

    export EXTRA_CPP_FLAGS="$CXXFLAGS -std=gnu++98 -fno-delete-null-pointer-checks -fno-lifetime-dse -fno-strict-overflow"
    export EXTRA_CFLAGS="$CFLAGS -std=gnu89 -Wno-error -fno-delete-null-pointer-checks -fno-lifetime-dse -fno-strict-overflow -Wno-incompatible-pointer-types -Wno-int-conversion -Wno-implicit-function-declaration"

    if [ -x ./autogen.sh ]; then
      ./autogen.sh
    else
      autoreconf -fi
    fi
  '';

  configureFlags = [
    "--disable-dependency-tracking"
    "--disable-downloading"
    "--disable-precompiled-headers"
    "--disable-docs"
    "--disable-system-pcsc"
    "--disable-system-sctp"
    "--with-openjdk-src-zip=${openjdkGit}"
    "--with-hotspot-src-zip=${hotspotDrop}"
    "--with-jdk-home=${boot-jdk}/lib/openjdk"
    "--with-curves=nist+"
    "--with-pkgversion=nixpkgs-bootstrap"
    # Pin C99/C++98 so OpenJDK 8's K&R prototypes still compile under
    # gcc-15's C23 default (`void f();` no longer means `f(...)`).
    "--with-extra-cflags=-std=gnu89"
    "--with-extra-cxxflags=-std=gnu++98"
  ];

  buildPhase = ''
    runHook preBuild
    bash_path="$(command -v bash)"

    # Inject permissive flags only at build time. Setting them during
    # configure breaks IcedTea's `-Werror` cxxflag probes — gcc treats
    # `command-line option '-std=gnu89' is valid for C/ObjC but not
    # for C++` as fatal under -Werror, rejecting -std=gnu++98 outright.
    export NIX_CFLAGS_COMPILE="-std=gnu89 -fno-delete-null-pointer-checks -fno-lifetime-dse -fno-strict-overflow $NIX_CFLAGS_COMPILE"

    make stamps/extract.stamp SHELL="$bash_path" -j$NIX_BUILD_CORES || true

    # Patch absolute /bin/* and /usr/bin/* and ALSA paths in the
    # extracted forest (see openjdk7-icedtea for the same patterns).
    set +o pipefail
    find openjdk* -name 'Sanity.gmk' 2>/dev/null \
      | xargs -r sed -i \
          -e "s|/usr/include/alsa/version.h|${alsa-lib.dev}/include/alsa/version.h|g" \
          -e "s|/usr/lib/libasound.so|${alsa-lib.out}/lib/libasound.so|g" || true
    find openjdk* -name 'Defs-utils.gmk' 2>/dev/null \
      | xargs -r sed -i \
          -e 's|\$(UTILS_COMMAND_PATH)||g' \
          -e 's|\$(UTILS_USR_BIN_PATH)||g' \
          -e 's|\$(UTILS_CCS_BIN_PATH)||g' \
          -e 's|\$(UTILS_DEVTOOL_PATH)||g' \
          -e 's|/bin/echo -e|echo -e|g' \
          -e 's|/bin/echo|echo|g' \
          -e 's|/usr/bin/echo|echo|g' \
          -e 's|/bin/sh\b|sh|g' || true
    find openjdk* -name 'Defs-linux.gmk' 2>/dev/null \
      | xargs -r sed -i \
          -e 's|UNIXCOMMAND_PATH\s*=\s*/bin/|UNIXCOMMAND_PATH = |' \
          -e 's|USRBIN_PATH\s*=\s*/usr/bin/|USRBIN_PATH = |' || true
    find openjdk* -name 'mawt.gmk' 2>/dev/null \
      | xargs -r perl -i -0pe 's|-I\$\(firstword \$\(wildcard \$\(OPENWIN_HOME\)/include/X11/extensions\) \\\s*\$\(wildcard /usr/include/X11/extensions\)\)|-I${xorgproto}/include|g' || true

    # glibc-2.42 uabs collision (rename to uabs_g) and gcc-15 C23
    # rejecting `typedef int bool;` and K&R `void f();` prototypes.
    for ht in openjdk/hotspot openjdk-boot/hotspot; do
      [ -d "$ht" ] && find "$ht" -type f \( -name '*.cpp' -o -name '*.hpp' \) \
        -exec sed -i -E 's/\buabs\b/uabs_g/g' {} + || true
    done
    for sa in openjdk{,-boot}/hotspot/agent/src/os/linux/libproc.h; do
      [ -f "$sa" ] && sed -i 's|^typedef int bool;|#include <stdbool.h>|' "$sa" || true
    done
    for jh in openjdk{,-boot}/jdk/src/share/native/common/jni_util.h; do
      [ -f "$jh" ] && sed -i 's|^void initializeEncoding();$|void initializeEncoding(JNIEnv *env);|' "$jh" || true
    done

    # Hotspot ignores --with-extra-cxxflags. Append flags directly.
    for gm in openjdk{,-boot}/hotspot/make/linux/makefiles/gcc.make; do
      [ -f "$gm" ] && \
        printf '\nCFLAGS += -std=gnu++98 -fpermissive -Wno-error -Wno-narrowing -Wno-error=incompatible-pointer-types -Wno-error=int-conversion\n' >> "$gm"
    done

    # Make-cmdline overrides propagate via MAKEFLAGS to all submakes
    # (env-only ALT_*= isn't reliable through deep nesting).
    tool_overrides=(
      SORT=sort WC=wc NAWK=gawk AWK=gawk MKDIR=mkdir
      LS=ls MV=mv "RM=rm -f" CP=cp CHMOD=chmod
      CAT=cat SED=sed GREP=grep EGREP=egrep FGREP=fgrep
      DATE=date PWD=pwd TR=tr "ECHO=echo -e" FIND=find
      EXPR=expr BASENAME=basename DIRNAME=dirname
      GZIP=gzip BZIP2=bzip2 TAR=tar TOUCH=touch
      LN=ln SH=bash CUT=cut HEAD=head TAIL=tail
      ID=id UNAME=uname WHICH=which TEE=tee
      TEST=test TRUE=true FALSE=false PRINTF=printf
    )
    export ALT_UNIXCOMMAND_PATH= ALT_USRBIN_PATH= ALT_DEVTOOLS_PATH= \
           ALT_COMPILER_PATH= ALT_UNIXCCS_PATH=
    export ALT_CUPS_HEADERS_PATH=${cups.dev}/include
    export ALT_FREETYPE_HEADERS_PATH=${freetype.dev}/include
    export ALT_FREETYPE_LIB_PATH=${freetype.out}/lib

    make icedtea-boot SHELL="$bash_path" -j$NIX_BUILD_CORES "''${tool_overrides[@]}"
    make              SHELL="$bash_path" -j$NIX_BUILD_CORES "''${tool_overrides[@]}"
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -d $out/lib/openjdk
    cp -a openjdk.build/images/j2sdk-image/. $out/lib/openjdk/
    rm -f $out/lib/openjdk/src.zip \
          $out/lib/openjdk/server/classes.jsa \
          $out/lib/openjdk/jre/bin/policytool
    find $out -name '*.la' -delete
    runHook postInstall
  '';

  passthru.home = "${placeholder "out"}/lib/openjdk";

  meta = {
    description = "OpenJDK 8 via IcedTea 3.35.0 (full-source bootstrap)";
    homepage = "https://icedtea.classpath.org/";
    license = lib.licenses.gpl2Plus;
    platforms = [
      "x86_64-linux"
      "i686-linux"
    ];
  };
}
