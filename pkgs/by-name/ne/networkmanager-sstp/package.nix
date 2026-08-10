{
  stdenv,
  lib,
  autoreconfHook,
  fetchurl,
  file,
  glib,
  gnome,
  gtk3,
  gtk4,
  gettext,
  libnma,
  libnma-gtk4,
  libsecret,
  networkmanager,
  pkg-config,
  ppp,
  sstp,
  withGnome ? true,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "NetworkManager-sstp";
  version = "1.3.2";
  name = "NetworkManager-sstp${lib.optionalString withGnome "-gnome"}-${finalAttrs.version}";

  src = fetchurl {
    url = "mirror://gnome/sources/NetworkManager-sstp/${lib.versions.majorMinor finalAttrs.version}/NetworkManager-sstp-${finalAttrs.version}.tar.xz";
    sha256 = "sha256-zd+g86cZLyibLhYLal6XzUb9wFu7kHROp0KzRM95Qng=";
  };

  nativeBuildInputs = [
    autoreconfHook
    file
    gettext
    glib # for gdbus-codegen
    pkg-config
  ]
  ++ lib.optionals withGnome [
    gtk4 # for gtk4-builder-tool
  ];

  buildInputs = [
    sstp
    networkmanager
    ppp
  ]
  ++ lib.optionals withGnome [
    gtk3
    gtk4
    libsecret
    libnma
    libnma-gtk4
  ];

  postPatch = ''
    sed -i 's#/sbin/pppd#${ppp}/bin/pppd#' src/nm-sstp-service.c
    sed -i 's#/sbin/sstpc#${sstp}/bin/sstpc#' src/nm-sstp-service.c
  '';

  configureFlags = [
    "--with-gnome=${lib.boolToYesNo withGnome}"
    "--with-gtk4=${lib.boolToYesNo withGnome}"
    "--with-pppd-plugin-dir=$(out)/lib/pppd/2.5.0"
    "--enable-absolute-paths"
  ];

  strictDeps = true;

  passthru = {
    updateScript = gnome.updateScript {
      packageName = "NetworkManager-sstp";
      attrPath = "networkmanager-sstp";
    };
    networkManagerPlugin = "VPN/nm-sstp-service.name";
  };

  meta = {
    description = "NetworkManager's sstp plugin";
    inherit (networkmanager.meta) maintainers teams platforms;
    license = lib.licenses.gpl2Plus;
  };
})
