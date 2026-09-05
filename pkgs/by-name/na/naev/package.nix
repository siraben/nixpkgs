{
  lib,
  stdenv,
  fetchurl,
  pkg-config,
  python3,
  rust-bindgen,
  cargo,
  clang,
  rustc,
  rustPlatform,
  sdl3,
  dav1d,
  enet,
  freetype,
  glpk,
  intltool,
  libgit2,
  libssh2,
  libunibreak,
  libopus,
  libvorbis,
  libxml2,
  luajit,
  meson,
  ninja,
  openal,
  openblas,
  openssl,
  pcre2,
  physfs,
  suitesparse,
  cmark,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "naev";
  version = "0.13.5";

  src = fetchurl {
    url = "https://codeberg.org/naev/naev/releases/download/v${finalAttrs.version}/naev-${finalAttrs.version}-source.tar.xz";
    hash = "sha256-WUmHZWLThVxJrOM3YmiWKfy1mu4zxjwK2HAJIPeEGiA=";
  };

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) src;
    hash = "sha256-RiykAlWc8W6s+YoJlRN1m+HuHu33jxProYiKl7FtPqs=";
    postPatch = ''
      cp ${./Cargo.lock} Cargo.lock
    '';
  };

  buildInputs = [
    sdl3
    dav1d
    enet
    freetype
    glpk
    libgit2
    libssh2
    libunibreak
    libopus
    libvorbis
    libxml2
    luajit
    openal
    openblas
    openssl
    pcre2
    physfs
    suitesparse
    cmark
  ];

  nativeBuildInputs = [
    (python3.withPackages (
      ps: with ps; [
        pyyaml
        mutagen
      ]
    ))
    rust-bindgen
    cargo
    clang
    rustc
    rustPlatform.bindgenHook
    rustPlatform.cargoSetupHook
    meson
    ninja
    pkg-config
    intltool
  ];

  LIBGIT2_SYS_USE_PKG_CONFIG = true;
  LIBSSH2_SYS_USE_PKG_CONFIG = true;

  mesonFlags = [
    "-Ddocs_c=disabled"
    "-Ddocs_lua=disabled"
    "-Dluajit=enabled"
  ];

  postConfigure = ''
    cp ../Cargo.lock Cargo.lock
  '';

  postPatch = ''
    patchShebangs --build dat utils

    cp ${./Cargo.lock} Cargo.lock
    substituteInPlace meson.build \
      --replace-fail "cargo_env = [ 'CARGO_HOME=' + meson.project_build_root() / 'cargo-home' ]" \
                     "cargo_env = [ 'CARGO_HOME=' + meson.project_source_root() / '.cargo' ]"
  '';

  meta = {
    description = "2D action/rpg space game";
    mainProgram = "naev";
    homepage = "https://naev.org";
    changelog = "https://codeberg.org/naev/naev/src/tag/v${finalAttrs.version}/Changelog.md";
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [ ralismark ];
    platforms = lib.platforms.linux;
  };
})
