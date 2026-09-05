{
  cmocka,
  docbook_xml_dtd_44,
  docbook-xsl-ns,
  fetchFromGitHub,
  lib,
  libx11,
  libxinerama,
  libxpm,
  libxrandr,
  libxslt,
  meson,
  ninja,
  pkg-config,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "stalonetray";
  version = "1.5.0";

  src = fetchFromGitHub {
    owner = "d3adb5";
    repo = "stalonetray";
    tag = finalAttrs.version;
    hash = "sha256-8qf9WFvYdvBnX+Eca8vkAMDYkmEra9B9q+RkRhIXkX4=";
  };

  postPatch = ''
    substituteInPlace generate-manpage.sh \
      --replace-fail "/usr/share/xml/docbook/stylesheet/docbook-xsl-nons" \
        "${docbook-xsl-ns}/share/xml/docbook-xsl-ns"
  '';

  nativeBuildInputs = [
    docbook-xsl-ns
    docbook_xml_dtd_44
    libxslt
    meson
    ninja
    pkg-config
  ];

  buildInputs = [
    cmocka
    libx11
    libxinerama
    libxpm
    libxrandr
  ];

  mesonFlags = [
    "-Dnative_kde=enabled"
    "-Drandr=enabled"
    "-Dtests=enabled"
    "-Dxinerama=enabled"
    "-Dxpm=enabled"
  ];

  doCheck = true;

  meta = {
    description = "Stand alone tray";
    homepage = "https://github.com/d3adb5/stalonetray";
    changelog = "https://github.com/d3adb5/stalonetray/releases/tag/${finalAttrs.version}";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ raskin ];
    mainProgram = "stalonetray";
  };
})
