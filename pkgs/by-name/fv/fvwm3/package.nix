{
  lib,
  asciidoctor,
  cairo,
  fetchFromGitHub,
  gettext,
  go,
  fontconfig,
  freetype,
  fribidi,
  libsm,
  libx11,
  libxcursor,
  libxext,
  libxfixes,
  libxft,
  libxkbcommon,
  libxpm,
  libxrandr,
  libxrender,
  libxt,
  libevent,
  libintl,
  libpng,
  librsvg,
  meson,
  ninja,
  perl,
  pkg-config,
  python3Packages,
  runtimeShell,
  stdenv,
  xtrans,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "fvwm3";
  version = "1.1.5";

  src = fetchFromGitHub {
    owner = "fvwmorg";
    repo = "fvwm3";
    rev = finalAttrs.version;
    hash = "sha256-ODvQiIunMqzPe4fbA6bCtp2+E7L8Eo4m1peX99ZcglQ=";
  };

  nativeBuildInputs = [
    asciidoctor
    gettext
    meson
    ninja
    perl
    pkg-config
    python3Packages.python
    python3Packages.wrapPython
  ]
  ++ lib.optional (stdenv.buildPlatform.canExecute stdenv.hostPlatform) go;

  buildInputs = [
    cairo
    fontconfig
    freetype
    fribidi
    libsm
    libx11
    libxcursor
    libxext
    libxfixes
    libxft
    libxkbcommon
    libxpm
    libxrandr
    libxrender
    libxt
    libevent
    libintl
    libpng
    librsvg
    perl
    python3Packages.python
    xtrans
  ];

  pythonPath = [
    python3Packages.pyxdg
  ];

  postPatch = ''
    substituteInPlace modules/FvwmForm/FvwmTalk-wrapper.in \
      --replace-fail '#!/bin/sh' '#!${runtimeShell}'
  '';

  mesonBuildDir = "builddir";

  mesonFlags = [
    (lib.mesonEnable "golang" (stdenv.buildPlatform.canExecute stdenv.hostPlatform))
    (lib.mesonBool "mandoc" true)
  ];

  preBuild = ''
    export GOCACHE=$TMPDIR/go-cache
  '';

  postFixup = ''
    wrapPythonPrograms
  '';

  enableParallelBuilding = true;

  strictDeps = true;

  meta = {
    homepage = "http://fvwm.org";
    description = "Multiple large virtual desktop window manager - Version 3";
    longDescription = ''
      Fvwm is a virtual window manager for the X windows system. It was
      originally a feeble fork of TWM by Robert Nation in 1993 (fvwm history),
      and has evolved into the fantastic, fabulous, famous, flexible, and so on,
      window manager we have today.

      Fvwm is a ICCCM/EWMH compliant and highly configurable floating window
      manager built primarily using Xlib. Fvwm is configured using a
      configuration file, which is used to configure most aspects of the window
      manager including window looks, key bindings, menus, window behavior,
      additional modules, and more. There is a default configuration file that
      can be used as a starting point for writing one's own configuration file.

      Fvwm is a light weight window manager and can be configured to be anything
      from a small sleek window manager to a full featured desktop
      environment. To get the most out of fvwm, one should be willing to read
      the documents, and take the time to write a custom configuration file that
      suites their needs. The manual pages and the fvwm wiki can be used to help
      learn how to configure fvwm.
    '';
    changelog = "https://github.com/fvwmorg/fvwm3/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    license = lib.licenses.gpl2Plus;
    maintainers = [ ];
    inherit (libx11.meta) platforms;
  };
})
