{
  lib,
  stdenv,
  fetchurl,
  java-gcj-compat,
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
  xorgproto,
  gtk2,
  cairo,
  pango,
  gdk-pixbuf,
  harfbuzz,
  fribidi,
  lcms2,
  libjpeg_turbo,
  giflib,
  krb5,
  expat,
  libxslt,
  libxml2,
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

# IcedTea 2.6.28 driving the OpenJDK 7 build.
#
# Boot toolchain is gcj+ECJ via java-gcj-compat, so this stage runs
# under interpreted gij and is correspondingly slow (hours). Admits two
# pure-Java jars as source per the bootstrappable.org Java convention:
# Apache Ant 1.9.16 (build system) and Mozilla Rhino 1.7.7.2 (script).

let
  version = "2.6.28";

  drop = name: hash: fetchurl {
    url = "https://icedtea.classpath.org/download/drops/icedtea7/${version}/${name}";
    inherit hash;
  };
  openjdkDrop = drop "openjdk.tar.bz2"
    "sha512-nFfWe9VfW6upek8ADsXiPYURaC76CKXEeAuwms+TY8pkC9sYfmC/XbxWSwTkucqopekoVZBSYBVXzjkOcFb9Dg==";
  corbaDrop = drop "corba.tar.bz2"
    "sha512-lxnwmqznIK9vsswyZrBwWLmCxXrhV/6SEOggKIhKWFGbpqZ+Y/z5Ax2UOZmxTGBm0gdpRPxFjPZv2K1fFKuYdg==";
  jaxpDrop = drop "jaxp.tar.bz2"
    "sha512-U5JSj1ziyKSHJLGEzanVD2qf7s7IOk01aOZKNcJDlv4Jyl03FsrNa8uebqAEJ/HvOS99oW6aGOCYqLtPtITZFA==";
  jaxwsDrop = drop "jaxws.tar.bz2"
    "sha512-VtqJw0EgKVw59timcr5iFAWde3QUB/+hAqewUZoZsEMC0bMy2XxXfkZk/NYhf2c6UwCOatqJM2CS1q/m6YOzwA==";
  jdkDrop = drop "jdk.tar.bz2"
    "sha512-m8B5vz4o6iEbS/T3OFB+y1YQ4Y4n/0r36L3+o8LSGdqkoAHx4tnKcafnOGuc5A1fFv+YW3BiR2GjdSGbjWmfWw==";
  langtoolsDrop = drop "langtools.tar.bz2"
    "sha512-aqIu4JUIAecQ5H7wCuf7CGu+9AbR2VwxvYsW/5JUZBZzY2/fKkkir9XqC50vI9jtHsbGi260BV6VpogC/hyYPA==";
  hotspotDrop = drop "hotspot.tar.bz2"
    "sha512-2g/WqQVe2Crf/In5VbJC7C+5kn1Z8Ck0+8yIXqeH+BZh3CNeUuhZ+4cmOd7wmaBv98exoaX8FkF/1aZU87/cIw==";

  apacheAnt = fetchurl {
    url = "https://dlcdn.apache.org/ant/binaries/apache-ant-1.9.16-bin.tar.gz";
    hash = "sha512-jVQqemNqSR52FwFIiBtvQT9FZKrRqwNPQmvZRr6TOCABhivWxghlqitXs5uWM+AYH+iZfdYyMSOq92tBDsSjZg==";
  };

  mozillaRhino = fetchurl {
    url = "https://github.com/mozilla/rhino/releases/download/Rhino1_7_7_2_Release/rhino-1.7.7.2.jar";
    hash = "sha512-cj+9WxJPKD6dhwR+CHOsTzWTm0a8iN9vYk1uB3OmbK6WoOIJMAIEGWBmksa+zfz5vopIajLcUd9q9Lc1Yn9R7w==";
  };
in

stdenv.mkDerivation {
  pname = "openjdk7-icedtea";
  inherit version;

  src = fetchurl {
    url = "https://icedtea.classpath.org/download/source/icedtea-${version}.tar.xz";
    hash = "sha512-AKPE5p1Qw2VlPRr7nzRICedIAvrZHPFTRx3kCWdzluptH05o7uxFuwqfw2i2oxCAR9xXlg4ql1FYxmIzV1CSpw==";
  };

  patches = [
    ./framework-patches/autoconf-2.7x.patch
    ./framework-patches/fix-xattr-include.patch
  ];

  # Drop /bin/echo and /bin/pwd from the framework Makefiles; they fire
  # before openjdk-boot extraction so postExtract is too late.
  postPatch = ''
    sed -e "s/--check/-c/g" -i Makefile.am
    find . -maxdepth 3 -type f \( -name 'Makefile*' -o -name '*.gmk' -o -name '*.am' -o -name '*.in' -o -name '*.sh' \) \
      | xargs -r sed -i -e 's|/bin/echo|echo|g' -e 's|/bin/pwd|pwd|g' || true
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
    java-gcj-compat
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
    gtk2
    cairo
    pango
    gdk-pixbuf
    harfbuzz
    fribidi
    lcms2
    libjpeg_turbo
    giflib
    krb5
    expat
    libxslt
    libxml2
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
    CFLAGS = "-Wno-incompatible-pointer-types -Wno-int-conversion";
    LD_LIBRARY_PATH = "";
  };

  preConfigure = ''
    # Stage drops at absolute paths so post-cd Makefile rules (e.g.
    # rewrite-rhino) can still find them.
    mkdir -p icedtea-drops third-party/apache-ant third-party/rhino
    drops_abs=$(realpath icedtea-drops)
    rhino_abs=$(realpath third-party/rhino)
    ant_abs=$(realpath third-party/apache-ant)

    cp ${openjdkDrop}    "$drops_abs/openjdk.tar.bz2"
    cp ${corbaDrop}      "$drops_abs/corba.tar.bz2"
    cp ${jaxpDrop}       "$drops_abs/jaxp.tar.bz2"
    cp ${jaxwsDrop}      "$drops_abs/jaxws.tar.bz2"
    cp ${jdkDrop}        "$drops_abs/jdk.tar.bz2"
    cp ${langtoolsDrop}  "$drops_abs/langtools.tar.bz2"
    cp ${hotspotDrop}    "$drops_abs/hotspot.tar.bz2"

    tar -C "$ant_abs" --strip-components=1 -xzf ${apacheAnt}
    cp ${mozillaRhino} "$rhino_abs/rhino-1.7.7.2.jar"

    mkdir -p icedtea-patches
    cp ${./distribution-patches}/*.patch icedtea-patches/
    export DISTRIBUTION_PATCHES="$(echo icedtea-patches/*.patch)"

    # Ant + ECJ-as-javac on PATH.
    export PATH="$PATH:$ant_abs/bin:${java-gcj-compat}/lib/jvm/java-1.5-gcj/bin"

    # Pin pre-C++11 / pre-C99 dialects so legacy K&R prototypes and
    # implicit narrowing in OpenJDK 7's hotspot/jdk still compile.
    export EXTRA_CPP_FLAGS="$CXXFLAGS -std=gnu++98 -fno-delete-null-pointer-checks -fno-lifetime-dse -fno-strict-overflow"
    export EXTRA_CFLAGS="$CFLAGS -std=gnu89 -Wno-error -fno-delete-null-pointer-checks -fno-lifetime-dse -fno-strict-overflow -Wno-incompatible-pointer-types -Wno-int-conversion -Wno-implicit-function-declaration"

    if [ -x ./autogen.sh ]; then ./autogen.sh; else autoreconf -fi; fi
  '';

  configureFlags = [
    "--disable-dependency-tracking"
    "--disable-downloading"
    "--disable-arm32-jit"
    "--disable-docs"
    "--disable-system-pcsc"
    "--disable-system-sctp"
    "--with-rhino=${mozillaRhino}"
    "--with-openjdk-src-zip=${openjdkDrop}"
    "--with-hotspot-src-zip=${hotspotDrop}"
    "--with-corba-src-zip=${corbaDrop}"
    "--with-jaxp-src-zip=${jaxpDrop}"
    "--with-jaxws-src-zip=${jaxwsDrop}"
    "--with-jdk-src-zip=${jdkDrop}"
    "--with-langtools-src-zip=${langtoolsDrop}"
    "--with-jdk-home=${java-gcj-compat}/lib/jvm/java-1.5-gcj"
    "--with-pkgversion=nixpkgs-bootstrap"
  ];

  buildPhase = ''
    runHook preBuild
    bash_path="$(command -v bash)"

    # Extract + clone-and-patch openjdk-boot.
    make stamps/extract.stamp SHELL="$bash_path" -j$NIX_BUILD_CORES
    make stamps/patch-boot.stamp SHELL="$bash_path" -j$NIX_BUILD_CORES

    # Patch out /bin /usr/bin absolute paths and the empty -I that
    # mawt.gmk's $(firstword $(wildcard ...)) leaves behind when the
    # X11 paths it probes don't exist in the Nix sandbox.
    set +o pipefail
    find openjdk-boot openjdk -name 'Sanity.gmk' 2>/dev/null \
      | xargs -r sed -i \
          -e "s|/usr/include/alsa/version.h|${alsa-lib.dev}/include/alsa/version.h|g" \
          -e "s|/usr/lib/libasound.so|${alsa-lib.out}/lib/libasound.so|g" || true
    find openjdk-boot openjdk -name 'Defs-linux.gmk' 2>/dev/null \
      | xargs -r sed -i \
          -e 's|UNIXCOMMAND_PATH\s*=\s*/bin/|UNIXCOMMAND_PATH = |' \
          -e 's|USRBIN_PATH\s*=\s*/usr/bin/|USRBIN_PATH = |' \
          -e 's|UNIXCCS_PATH\s*=\s*/usr/ccs/bin/|UNIXCCS_PATH = |' \
          -e 's|DEVTOOLS_PATH\s*=\s*/usr/bin/|DEVTOOLS_PATH = |' || true
    find openjdk-boot openjdk -name 'Defs-utils.gmk' 2>/dev/null \
      | xargs -r sed -i \
          -e 's|\$(UTILS_COMMAND_PATH)||g' \
          -e 's|\$(UTILS_USR_BIN_PATH)||g' \
          -e 's|\$(UTILS_CCS_BIN_PATH)||g' \
          -e 's|\$(UTILS_DEVTOOL_PATH)||g' \
          -e 's|/bin/echo -e|echo -e|g' \
          -e 's|/bin/echo|echo|g' \
          -e 's|/usr/bin/echo|echo|g' \
          -e 's|/bin/sh\b|sh|g' || true
    find openjdk-boot openjdk -name 'mawt.gmk' 2>/dev/null \
      | xargs -r perl -i -0pe 's|-I\$\(firstword \$\(wildcard \$\(OPENWIN_HOME\)/include/X11/extensions\) \\\s*\$\(wildcard /usr/include/X11/extensions\)\)|-I${xorgproto}/include|g' || true

    # OUTPUTDIRs that Defs.gmk sanity-checks before any rule creates them.
    mkdir -p openjdk.build-boot openjdk.build

    # Empty *_PATH defaults so PATH lookup applies. ALT_*= env vars
    # alone aren't reliable through deep submakes; the make command-
    # line tool_overrides below propagate via MAKEFLAGS to fix that.
    export ALT_UNIXCOMMAND_PATH= ALT_USRBIN_PATH= ALT_DEVTOOLS_PATH= \
           ALT_COMPILER_PATH= ALT_UNIXCCS_PATH=
    export ALT_CUPS_HEADERS_PATH=${cups.dev}/include
    export ALT_FREETYPE_HEADERS_PATH=${freetype.dev}/include
    export ALT_FREETYPE_LIB_PATH=${freetype.out}/lib

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
    make icedtea-boot SHELL="$bash_path" -j$NIX_BUILD_CORES "''${tool_overrides[@]}"
    make              SHELL="$bash_path" -j$NIX_BUILD_CORES "''${tool_overrides[@]}"
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -d $out/lib/openjdk
    cp -a openjdk.build/j2sdk-image/. $out/lib/openjdk/
    rm -f $out/lib/openjdk/src.zip
    runHook postInstall
  '';

  passthru.home = "${placeholder "out"}/lib/openjdk";

  meta = {
    description = "OpenJDK 7 via IcedTea 2.6.28 (full-source bootstrap)";
    homepage = "https://icedtea.classpath.org/";
    license = lib.licenses.gpl2Plus;
    platforms = [
      "x86_64-linux"
      "i686-linux"
    ];
  };
}
