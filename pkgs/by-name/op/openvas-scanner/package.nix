{
  lib,
  stdenv,
  bison,
  cmake,
  curl,
  doxygen,
  fetchFromGitHub,
  file,
  git,
  glib,
  gnutls,
  gpgme,
  gvm-libs,
  json-glib,
  krb5,
  libbsd,
  libclang,
  libgcrypt,
  libksba,
  libpcap,
  libsepol,
  libssh,
  libtasn1,
  net-snmp,
  p11-kit,
  paho-mqtt-c,
  pandoc,
  pcre2,
  pkg-config,
  util-linux,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "openvas-scanner";
  version = "23.50.24";

  src = fetchFromGitHub {
    owner = "greenbone";
    repo = "openvas-scanner";
    tag = "v${finalAttrs.version}";
    hash = "sha256-WXrAE2p7gSwjdK3Qy6dW3/stnhWgM86a7vvlP+Vkaks=";
  };

  patches = [ ./fix-gcc-15-build.patch ];

  nativeBuildInputs = [
    cmake
    git
    doxygen
    pandoc
    pkg-config
  ];

  buildInputs = [
    bison
    curl
    file
    glib
    gnutls
    gpgme
    gvm-libs
    json-glib
    krb5
    libbsd
    libclang
    libgcrypt
    libksba
    libpcap
    libsepol
    libssh
    libtasn1
    net-snmp
    p11-kit
    paho-mqtt-c
    pcre2
    util-linux
  ];

  cmakeFlags = [
    "-DGVM_RUN_DIR=${placeholder "out"}/run/gvm"
    "-DLOCALSTATEDIR=${placeholder "out"}/var"
    "-DSYSCONFDIR=${placeholder "out"}/etc"
    "-DOPENVAS_RUN_DIR=${placeholder "out"}/run/ospd"
    "-DOPENVAS_FEED_LOCK_PATH=${placeholder "out"}/var/lib/openvas/feed-update.lock"
  ];

  meta = {
    description = "Scanner component for Greenbone Community Edition";
    homepage = "https://github.com/greenbone/openvas-scanner";
    changelog = "https://github.com/greenbone/openvas-scanner/blob/${finalAttrs.src.rev}/changelog.toml";
    license = lib.licenses.gpl2Only;
    maintainers = with lib.maintainers; [ fab ];
    mainProgram = "openvas-scanner";
    platforms = lib.platforms.all;
  };
})
