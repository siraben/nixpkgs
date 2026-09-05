{
  lib,
  gccStdenv,
  fetchFromGitHub,
  nix-update-script,
  autoconf,
  automake,
  libtool,
  pkg-config,
  freetype,
  SDL,
  libx11,
}:
let
  stdenv = gccStdenv;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "agg";
  version = "2.8.42";

  src = fetchFromGitHub {
    owner = "cppfw";
    repo = "agg";
    tag = finalAttrs.version;
    hash = "sha256-AADWEn3heNUkZzADUU8cFRczeyES5BPeyXLuan93y4k=";
  };

  sourceRoot = "source/src/agg";
  nativeBuildInputs = [
    pkg-config
    autoconf
    automake
    libtool
  ];
  buildInputs = [
    freetype
    SDL
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    libx11
  ];

  postPatch = ''
    # The maintained build uses headers from include/agg, while the bundled
    # autotools files still expect them directly under include.
    cp -r include/agg/. include/

    substituteInPlace configure.ac \
      --replace-fail 'AC_INIT(agg, 2.7.0)' 'AC_INIT(agg, ${finalAttrs.version})'
  '';

  preConfigure = "sh autogen.sh";

  configureFlags = [
    (lib.enableFeature stdenv.hostPlatform.isLinux "platform")
    (lib.enableFeature (!stdenv.hostPlatform.isDarwin) "sdltest")
    "--enable-examples=no"
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    "--x-includes=${lib.getDev libx11}/include"
    "--x-libraries=${lib.getLib libx11}/lib"
  ];

  env.NIX_CFLAGS_COMPILE = toString [ "-fpermissive" ];

  doCheck = true;

  checkPhase = ''
    runHook preCheck

    for test in ../../tests/*/main.cpp; do
      test_bin="$TMPDIR/$(basename "$(dirname "$test")")"
      $CXX -std=c++11 -Iinclude "$test" -Lsrc/.libs -lagg -o "$test_bin"
      LD_LIBRARY_PATH=src/.libs "$test_bin"
    done

    runHook postCheck
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "High quality rendering engine for C++";

    longDescription = ''
      Anti-Grain Geometry (AGG) is an Open Source, free of charge
      graphic library, written in industrially standard C++.  The
      terms and conditions of use AGG are described on The License
      page.  AGG doesn't depend on any graphic API or technology.
      Basically, you can think of AGG as of a rendering engine that
      produces pixel images in memory from some vectorial data.  But
      of course, AGG can do much more than that.
    '';

    license = lib.licenses.mit;
    homepage = "https://github.com/cppfw/agg";
    changelog = "https://github.com/cppfw/agg/blob/${finalAttrs.version}/build/debian/changelog";
    platforms = lib.platforms.unix;
    hydraPlatforms = lib.platforms.linux; # build hangs on both Darwin platforms, needs investigation
  };
})
