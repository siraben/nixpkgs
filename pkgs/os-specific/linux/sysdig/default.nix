{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  cmake,
  kernel,
  installShellFiles,
  pkg-config,
  luajit,
  ncurses,
  perl,
  jsoncpp,
  openssl,
  curl,
  jq,
  gcc,
  elfutils,
  onetbb,
  protobuf,
  grpc,
  yaml-cpp,
  nlohmann_json,
  re2,
  zstd,
  uthash,
  clang,
  libbpf,
  bpftools,
}:

let
  # Compare with https://github.com/draios/sysdig/blob/0.41.4/cmake/modules/falcosecurity-libs.cmake
  libsRev = "0.21.0";
  libsHash = "sha256-2iJk7vAw9JaHeVqejmLj8mmcY9kn5NKPe1oax1tCWAs=";

  # Compare with https://github.com/falcosecurity/libs/blob/0.21.0/cmake/modules/valijson.cmake
  valijson = fetchFromGitHub {
    owner = "tristanpenman";
    repo = "valijson";
    rev = "v1.0.2";
    hash = "sha256-wvFdjsDtKH7CpbEpQjzWtLC4RVOU9+D2rSK0Xo1cJqo=";
  };

  # https://github.com/draios/sysdig/blob/0.41.4/cmake/modules/driver.cmake
  driver = fetchFromGitHub {
    owner = "falcosecurity";
    repo = "libs";
    rev = "8.1.0+driver";
    hash = "sha256-Nr4mMIIkRkb5aQs6NJmmRM0+Sr3/8p4jNFMg1XoIdRA=";
  };

  containerPluginSupported =
    stdenv.hostPlatform.isLinux && (stdenv.hostPlatform.isx86_64 || stdenv.hostPlatform.isAarch64);

  containerPlugin = fetchurl {
    url =
      "https://download.falco.org/plugins/stable/container-0.6.0-linux-"
      + (if stdenv.hostPlatform.isx86_64 then "x86_64" else "aarch64")
      + ".tar.gz";
    hash =
      if stdenv.hostPlatform.isx86_64 then
        "sha256-+cMi3Cqky9pJKl5iWFMvdx6WDbRVCaU7waUooB9LYWg="
      else
        "sha256-8gFaXHWLXreYaewVkzUq31yVWZDljggEe0wTRMawdnY=";
  };

  version = "0.41.4";
in
stdenv.mkDerivation {
  pname = "sysdig";
  inherit version;

  src = fetchFromGitHub {
    owner = "draios";
    repo = "sysdig";
    tag = version;
    hash = "sha256-FmKXHB2i9sZmVi+4m5FCZCQT62XBBEHAQeG9kOVHbjQ=";
  };

  postPatch =
    lib.optionalString containerPluginSupported ''
      substituteInPlace cmake/modules/container_plugin.cmake \
        --replace-fail 'URL "https://download.falco.org/plugins/stable/container-''${CONTAINER_VERSION}-''${PLUGINS_SYSTEM_NAME}-''${CMAKE_HOST_SYSTEM_PROCESSOR}.tar.gz"' \
        'URL "${containerPlugin}"'
    ''
    + lib.optionalString (!containerPluginSupported) ''
      # Upstream only publishes the bundled plugin for x86_64 and aarch64 Linux.
      substituteInPlace CMakeLists.txt \
        --replace-fail "include(container_plugin)" ""
    '';

  nativeBuildInputs = [
    cmake
    perl
    installShellFiles
    pkg-config
  ];
  buildInputs = [
    luajit
    ncurses
    openssl
    curl
    jq
    onetbb
    re2
    protobuf
    grpc
    yaml-cpp
    jsoncpp
    nlohmann_json
    zstd
    uthash
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    bpftools
    elfutils
    libbpf
    clang
    gcc
  ]
  ++ lib.optionals (kernel != null) kernel.moduleBuildDependencies;

  hardeningDisable = [
    "pic"
    "zerocallusedregs"
  ];

  postUnpack = ''
    cp -r ${
      fetchFromGitHub {
        owner = "falcosecurity";
        repo = "libs";
        rev = libsRev;
        hash = libsHash;
      }
    } libs
    chmod -R +w libs

    substituteInPlace \
      libs/userspace/libpman/libpman.pc.in \
      libs/userspace/libscap/libscap.pc.in \
      libs/userspace/libsinsp/libsinsp.pc.in \
      --replace-fail "\''${prefix}/@CMAKE_INSTALL_LIBDIR@" "@CMAKE_INSTALL_FULL_LIBDIR@" \
      --replace-fail "\''${prefix}/@CMAKE_INSTALL_INCLUDEDIR@" "@CMAKE_INSTALL_FULL_INCLUDEDIR@"

    cp -r ${driver} driver-src
    chmod -R +w driver-src

    cmakeFlagsArray+=(
      "-DFALCOSECURITY_LIBS_SOURCE_DIR=$(pwd)/libs"
      "-DDRIVER_SOURCE_DIR=$(pwd)/driver-src/driver"
    )
  '';

  cmakeFlags = [
    "-DUSE_BUNDLED_DEPS=OFF"
    "-DSYSDIG_VERSION=${version}"
    "-DUSE_BUNDLED_B64=OFF"
    "-DUSE_BUNDLED_TBB=OFF"
    "-DUSE_BUNDLED_RE2=OFF"
    "-DUSE_BUNDLED_JSONCPP=OFF"
    "-DCREATE_TEST_TARGETS=OFF"
    "-DVALIJSON_INCLUDE=${valijson}/include"
    "-DUTHASH_INCLUDE=${uthash}/include"
    (lib.cmakeBool "USE_BUNDLED_FALCOSECURITY_LIBS" true)
  ]
  ++ lib.optional (kernel == null) "-DBUILD_DRIVER=OFF";

  env.NIX_CFLAGS_COMPILE =
    # fix compiler warnings been treated as errors
    "-Wno-error";

  preConfigure = ''
    if ! grep -q "${libsRev}" cmake/modules/falcosecurity-libs.cmake; then
      echo "falcosecurity-libs checksum needs to be updated!"
      exit 1
    fi
    cmakeFlagsArray+=(-DCMAKE_EXE_LINKER_FLAGS="-ltbb -lcurl -lzstd -labsl_synchronization")
  ''
  + lib.optionalString (kernel != null) ''
    export INSTALL_MOD_PATH="$out"
    export KERNELDIR="${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  '';

  postInstall =
    lib.optionalString stdenv.hostPlatform.isLinux ''
      # Fix the bash completion location
      installShellCompletion --bash $out/etc/bash_completion.d/sysdig
      rm $out/etc/bash_completion.d/sysdig
      rmdir $out/etc/bash_completion.d
      rmdir $out/etc
    ''
    + lib.optionalString (kernel != null) ''
      make install_driver
      kernel_dev=${kernel.dev}
      kernel_dev=''${kernel_dev#${builtins.storeDir}/}
      kernel_dev=''${kernel_dev%%-linux*dev*}
      if test -f "$out/lib/modules/${kernel.modDirVersion}/extra/scap.ko"; then
          sed -i "s#$kernel_dev#................................#g" $out/lib/modules/${kernel.modDirVersion}/extra/scap.ko
      else
          for i in $out/lib/modules/${kernel.modDirVersion}/{extra,updates}/scap.ko.xz; do
            if test -f "$i"; then
              xz -d $i
              sed -i "s#$kernel_dev#................................#g" ''${i%.xz}
              xz -9 ''${i%.xz}
            fi
          done
      fi
    '';

  meta = {
    description = "Tracepoint-based system tracing tool for Linux (with clients for other OSes)";
    license = with lib.licenses; [
      asl20
      gpl2Only
      mit
    ];
    maintainers = with lib.maintainers; [ raskin ];
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    broken = kernel != null && ((lib.versionOlder kernel.version "4.14") || kernel.isZen);
    homepage = "https://sysdig.com/opensource/";
    downloadPage = "https://github.com/draios/sysdig/releases";
  };
}
