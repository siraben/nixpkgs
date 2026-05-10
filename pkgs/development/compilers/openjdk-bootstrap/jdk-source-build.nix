{
  lib,
  stdenv,
  fetchFromGitHub,
  autoconf,
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
  libxslt,
  libxml2,
  libpng,
  harfbuzz,
  lcms2,
  libjpeg_turbo,
  giflib,
  krb5,
  zlib,
  perl,
  file,
  which,
  makeWrapper,
  gnumake42,
}:

# Shared builder for OpenJDK 9+ from-source bootstrap stages.
# JDK 9/10 are built interpreter-only because gcc-15 miscompiles their
# JIT — their `bin/java` is wrapped with -Xint so downstream stages see
# clean output from the version probe.

{
  version,
  jdkRepo,
  gitRev,
  srcHash,
  patches ? [ ],
  boot-jdk,
}:

let
  major = lib.versions.major version;
  legacy = lib.versionOlder major "11";

  # Permissive/portable flags injected via the gcc-wrapper to coax legacy
  # hotspot through gcc-15's stricter defaults; -std=gnu++98 is added
  # for JDK 9/10 only (newer JDKs ship modern C++ themselves).
  cflags = lib.concatStringsSep " " (
    [
      "-std=gnu99"
      "-fpermissive"
      "-Wno-error"
      "-Wno-narrowing"
      "-Wno-int-conversion"
      "-Wno-incompatible-pointer-types"
      "-Wno-implicit-function-declaration"
      "-fno-strict-aliasing"
      "-fno-lifetime-dse"
      "-fcommon"
      "-fno-tree-vectorize"
      "-fno-tree-loop-vectorize"
      "-fno-tree-slp-vectorize"
    ]
    ++ lib.optional legacy "-std=gnu++98"
  );
in

stdenv.mkDerivation {
  pname = "openjdk-bootstrap-${major}";
  inherit version patches;

  src = fetchFromGitHub {
    owner = "openjdk";
    repo = jdkRepo;
    rev = gitRev;
    hash = srcHash;
  };

  nativeBuildInputs = [
    autoconf
    pkg-config
    zip
    unzip
    perl
    file
    which
    makeWrapper
    boot-jdk
  ]
  # JDK <11's Hadrian races on .vardeps with GNU make 4.4+.
  ++ lib.optional legacy gnumake42;

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
    libxslt
    libxml2
    libpng
    harfbuzz
    lcms2
    libjpeg_turbo
    giflib
    krb5
    zlib
  ];

  # Hadrian schedules its own sub-make jobs via JOBS.
  enableParallelBuilding = false;

  hardeningDisable = [
    "format"
    "fortify"
    "fortify3"
    "stackprotector"
    "pic"
  ];

  postPatch = ''
    # glibc 2.42 added a libc `uabs(int)` colliding with hotspot's
    # overloaded uabs; rename in-tree (cheaper and more robust than
    # Chainguard's per-version patch).
    if [ -d src/hotspot ]; then
      find src/hotspot -type f \( -name '*.cpp' -o -name '*.hpp' \) \
        -exec sed -i -E 's/\buabs\b/uabs_g/g' {} +
    fi
    # GenerateCurrencyData refuses cutover dates >10 y from build time;
    # those baked-in dates are now too old. Neuter the throw (the path
    # moved between JDK 9 and JDK 10+, so we hit both).
    find . \( -path '*/build/tools/generatecurrencydata/GenerateCurrencyData.java' \) \
      -exec sed -i 's|throw new RuntimeException("time is more than 10 years from present: " + time);|/* check disabled */|' {} +
  '';

  # JDK 19+'s jmod rejects --date < 1980-01-01T00:00:02Z. Stdenv defaults
  # to 1980-01-01T00:00:00Z, exactly two seconds short.
  env.SOURCE_DATE_EPOCH = "315532802";

  preConfigure = "chmod +x configure";
  configureScript = "bash configure";

  configureFlags = [
    "--with-boot-jdk=${boot-jdk}/lib/openjdk"
    "--disable-warnings-as-errors"
    "--disable-precompiled-headers"
    "--enable-dtrace=no"
    "--with-zlib=system"
    "--with-debug-level=release"
    "--with-native-debug-symbols=internal"
    # Both javac flavours time out under the -Xint boot JVM.
    "--disable-javac-server"
  ]
  ++ lib.optional (lib.versionAtLeast major "10" && lib.versionOlder major "19") "--disable-hotspot-gtest"
  ++ lib.optional (lib.versionOlder major "15") "--disable-sjavac"
  # gcc-15 miscompiles legacy hotspot at -O3 so badly that even -Xint
  # SEGVs; -O0 is the only level that produces a working JVM.
  ++ lib.optionals legacy [
    "--with-extra-cflags=-O0"
    "--with-extra-cxxflags=-O0"
  ];

  buildPhase = ''
    runHook preBuild
    export NIX_CFLAGS_COMPILE="${cflags} $NIX_CFLAGS_COMPILE"
    ${lib.optionalString legacy ''export _JAVA_OPTIONS="-Xint"''}
    make images JOBS=$NIX_BUILD_CORES LOG=info
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -d $out/lib/openjdk
    cp -a build/*/images/jdk/. $out/lib/openjdk/
    rm -f $out/lib/openjdk/src.zip $out/lib/openjdk/lib/server/classes.jsa

    ${lib.optionalString legacy ''
      # Wrap every Java launcher with -Xint (-J-Xint for tools) so the
      # next stage's configure sees a clean `java -version`.
      for tool in $out/lib/openjdk/bin/*; do
        [ -x "$tool" ] && [ ! -L "$tool" ] || continue
        file "$tool" 2>/dev/null | grep -q "ELF.*executable" || continue
        flag=$([ "$(basename "$tool")" = java ] && echo -Xint || echo -J-Xint)
        mv "$tool" "$tool.real"
        printf '%s\n' '#!/bin/sh' \
          'unset _JAVA_OPTIONS JAVA_TOOL_OPTIONS' \
          "exec \"$tool.real\" $flag \"\$@\"" > "$tool"
        chmod +x "$tool"
      done
    ''}

    runHook postInstall
  '';

  passthru.home = "${placeholder "out"}/lib/openjdk";

  meta = {
    description = "OpenJDK ${major} from openjdk/${jdkRepo} (full-source bootstrap)";
    homepage = "https://openjdk.org/";
    license = lib.licenses.gpl2Plus;
    platforms = [
      "x86_64-linux"
      "i686-linux"
    ];
  };
}
