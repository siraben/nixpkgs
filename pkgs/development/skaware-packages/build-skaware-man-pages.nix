{
  lib,
  stdenv,
  fetchFromSourcehut,
}:
lib.extendMkDerivation {
  constructDrv = stdenv.mkDerivation;
  excludeDrvArgNames = [
    "sha256"
    "description"
    "maintainers"
    "license"
    "owner"
    "repo"
    "rev"
  ];
  extendDrvArgs =
    finalAttrs:
    {
      pname,
      sha256,
      description,
      maintainers,
      license ? lib.licenses.isc,
      owner ? "~humm",
      repo ? pname,
      rev ? "v${finalAttrs.version}",
      meta ? { },
      ...
    }:
    let
      manDir = "${placeholder "out"}/share/man";
      src = fetchFromSourcehut {
        inherit
          owner
          repo
          rev
          sha256
          ;
      };
    in
    {
      inherit src;
      makeFlags = [
        "MAN_DIR=${manDir}"
      ];
      dontBuild = true;
      meta = {
        inherit description license maintainers;
        inherit (src.meta) homepage;
        platforms = lib.platforms.all;
      }
      // meta;
    };
}
