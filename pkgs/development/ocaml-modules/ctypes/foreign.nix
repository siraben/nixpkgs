{
  lib,
  stdenv,
  ocaml,
  buildDunePackage,
  ctypes,
  dune-configurator,
  libffi,
  ounit2,
  lwt,
}:

buildDunePackage {
  pname = "ctypes-foreign";

  inherit (ctypes) version src;

  buildInputs = [ dune-configurator ];

  propagatedBuildInputs = [
    ctypes
    libffi
  ];

  checkInputs = [
    ounit2
    lwt
  ];

  # These closure lifetime tests are killed by SIGBUS on aarch64-darwin.
  postPatch = lib.optionalString (stdenv.hostPlatform.isDarwin && stdenv.hostPlatform.isAarch64) ''
    substituteInPlace tests/test-callback_lifetime/dune \
      --replace-fail '(libraries' \
        '(action
           (run %{test} -only-test "Callback lifetime tests:0" -only-test "Callback lifetime tests:1"))
         (libraries'
  '';

  # Fix build with gcc 14
  env.NIX_CFLAGS_COMPILE = "-Wno-error=incompatible-pointer-types";

  # closure lifetime tests crash on darwin ocaml 5.5
  doCheck = !(stdenv.hostPlatform.isDarwin && lib.versionAtLeast ocaml.version "5.5");

  meta = ctypes.meta // {
    description = "Dynamic access to foreign C libraries using Ctypes";
  };
}
