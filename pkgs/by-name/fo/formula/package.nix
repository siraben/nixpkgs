{
  lib,
  fetchFromGitHub,
  buildDotnetModule,
  dotnetCorePackages,
  unstableGitUpdater,
  writeShellScript,
}:

buildDotnetModule (finalAttrs: {
  pname = "formula-dotnet";
  version = "2.0-unstable-2022-10-17";

  src = fetchFromGitHub {
    owner = "VUISIS";
    repo = "formula-dotnet";
    rev = "8d3b6e635ed94feb639aa843b1f0a33f86131f0f";
    hash = "sha256-0oczQrDDaw2r3fsALBTHn1hCp1FPET1pjbgrNl14+mc=";
  };

  patches = [ ./dotnet-8-upgrade.patch ];

  dotnet-sdk = dotnetCorePackages.sdk_8_0;
  nugetDeps = ./nuget.json;
  projectFile = "Src/CommandLine/CommandLine.csproj";
  dotnetFlags = [ "-p:Platform=x64" ];

  postFixup = ''
    mv $out/bin/CommandLine $out/bin/formula
  '';

  passthru.updateScript = unstableGitUpdater {
    url = finalAttrs.meta.homepage;
    tagConverter = writeShellScript "formula-version-converter" ''
      read -r tag
      if [ "$tag" = 0 ]; then
        echo 2.0
      else
        echo "''${tag#v}"
      fi
    '';
  };

  meta = {
    description = "Formal Specifications for Verification and Synthesis";
    homepage = "https://github.com/VUISIS/formula-dotnet";
    license = lib.licenses.mspl;
    maintainers = with lib.maintainers; [ siraben ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "formula";
  };
})
