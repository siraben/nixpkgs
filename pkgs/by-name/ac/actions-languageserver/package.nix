{
  lib,
  fetchFromGitHub,
  buildNpmPackage,
  buildPackages,
}:
buildNpmPackage (finalAttrs: {
  pname = "actions-languageserver";
  version = "0.3.61";
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "actions";
    repo = "languageservices";
    tag = "release-v${finalAttrs.version}";
    hash = "sha256-hNb4QcgBYfoiaa/X4BZeahiHsF11UwdNa4d+nh8sb3M=";
    postFetch = ''
      ${lib.getExe buildPackages.npm-lockfile-fix} $out/package-lock.json
      ${lib.getExe buildPackages.jq} 'del(.packages[].devDependencies.["rest-api-description"])' $out/package-lock.json | ${buildPackages.moreutils}/bin/sponge $out/package-lock.json
      ${lib.getExe buildPackages.jq} 'del(.devDependencies.["rest-api-description"])' $out/languageservice/package.json | ${buildPackages.moreutils}/bin/sponge $out/languageservice/package.json
    '';
  };

  npmWorkspace = "languageserver";

  npmDepsHash = "sha256-OozKfgupmOYX4LnKnPFw14sWD/yjRPk7a63hoJ4LD/Y=";

  preBuild = ''
    patchShebangs .
    npm run build --workspace=expressions
    npm run build --workspace=workflow-parser
    npm run build --workspace=languageservice
  '';

  # Copy workspace packages to output to fix symlinks
  postInstall = ''
    cp -r expressions workflow-parser languageservice languageserver $out/lib/node_modules/actions-languageservices/
  '';

  meta = {
    homepage = "https://github.com/actions/languageservices";
    description = "Language server for GitHub Actions";
    changelog = "https://github.com/actions/languageservices/releases/tag/release-v${finalAttrs.version}";

    mainProgram = "actions-languageserver";
    maintainers = with lib.maintainers; [ keirlawson ];
    license = with lib.licenses; [ mit ];
    platforms = [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
      "aarch64-linux"
    ];
  };
})
