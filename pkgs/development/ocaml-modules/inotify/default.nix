{
  lib,
  fetchFromGitHub,
  buildDunePackage,
  lwt, # optional lwt support
  ounit2,
  fileutils, # only for tests
}:

buildDunePackage (finalAttrs: {
  version = "2.6";
  pname = "inotify";

  src = fetchFromGitHub {
    owner = "whitequark";
    repo = "ocaml-inotify";
    rev = "v${finalAttrs.version}";
    hash = "sha256-Vg9uVIx6/OMS1WoJIHwZbSt5ZyFy+Xgw5167FJWGslg=";
  };

  buildInputs = [ lwt ];

  checkInputs = [
    ounit2
    fileutils
  ];

  doCheck = true;

  meta = {
    description = "Bindings for Linux’s filesystem monitoring interface, inotify";
    license = with lib.licenses; [
      lgpl21Only
      ocamlLgplLinkingException
    ];
    maintainers = [ lib.maintainers.vbgl ];
    inherit (finalAttrs.src.meta) homepage;
    platforms = lib.platforms.linux;
  };
})
