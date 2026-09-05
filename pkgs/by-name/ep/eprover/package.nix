{
  lib,
  stdenv,
  fetchFromGitHub,
  which,
  enableHO ? false,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "eprover";
  version = "3.5.1";

  src = fetchFromGitHub {
    owner = "eprover";
    repo = "eprover";
    tag = "E-${finalAttrs.version}";
    hash = "sha256-zHcU3WQx3HTKKCGjxJTVulqToIEofZiJs7bmD3Ktgms=";
  };

  buildInputs = [ which ];

  patches = [
    ./fix-cross-toolchains.patch
  ];

  configurePlatforms = [ ];

  configureFlags = [
    "--exec-prefix=$(out)"
    "--man-prefix=$(out)/share/man"
  ]
  ++ lib.optionals enableHO [
    "--enable-ho"
  ];

  # need to directly insert into makeFlagsArray as the makefile expects the binary
  # in the AR variable to already be passed the `rcs` flags, which requires us to
  # specify them. As this requires spaces, we need makeFlagsArray, as makeFlags
  # will just make the make script see the `rcs` as a target
  preBuild = ''
    makeFlagsArray+=(CC="${stdenv.cc.targetPrefix}cc" AR="${stdenv.cc.targetPrefix}ar rcs")
  '';

  meta = {
    description = "Automated theorem prover for full first-order logic with equality";
    homepage = "https://www.eprover.org/";
    license = lib.licenses.gpl2;
    maintainers = with lib.maintainers; [
      raskin
    ];
    platforms = lib.platforms.all;
  };
})
