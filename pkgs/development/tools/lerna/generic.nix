{
  lib,
  buildNpmPackage,
  fetchurl,
  version,
  hash,
  npmDepsHash,
  packageLockFile,
}:

buildNpmPackage (finalAttrs: {
  pname = "lerna";
  inherit version;

  src = fetchurl {
    url = "https://registry.npmjs.org/lerna/-/lerna-${finalAttrs.version}.tgz";
    inherit hash;
  };

  postPatch = ''
    ln -s ${packageLockFile} package-lock.json
  '';

  inherit npmDepsHash;
  dontNpmBuild = true;

  meta = {
    description = "Fast, modern build system for managing and publishing multiple JavaScript/TypeScript packages from the same repository";
    homepage = "https://lerna.js.org/";
    changelog = "https://github.com/lerna/lerna/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ThaoTranLePhuong ];
  };
})
