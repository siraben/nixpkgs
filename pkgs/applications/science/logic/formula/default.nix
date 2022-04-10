{ lib, stdenv, fetchFromGitHub, buildDotnetModule, dotnetCorePackages, unstableGitUpdater }:

buildDotnetModule rec {
  pname = "formula-dotnet";
  version = "2.0";

  src = fetchFromGitHub {
    owner = "VUISIS";
    repo = "formula-dotnet";
    rev = "26cb5172c64532720b6c5954ad64b8a57eca4b84";
    sha256 = "sha256-4TTiSSt+RrgQutFENc6eeYwLgs63obG+XgnCAeh4lwo=";
  };

  nugetDeps = ./nuget.nix;
  projectFile = "Src/CommandLine/CommandLine.csproj";

  dotnet-runtime = dotnetCorePackages.runtime_6_0;
  dotnet-sdk = dotnetCorePackages.sdk_6_0;
  postFixup = if stdenv.isLinux then ''
    mv $out/bin/CommandLine $out/bin/formula
  '' else lib.optionalString stdenv.isDarwin ''
    makeWrapper ${dotnetCorePackages.runtime_6_0}/bin/dotnet $out/bin/formula \
      --add-flags "$out/lib/formula-dotnet/CommandLine.dll" \
      --prefix DYLD_LIBRARY_PATH : $out/lib/formula-dotnet/runtimes/macos/native
  '';

  passthru.updateScript = unstableGitUpdater { url = meta.homepage; };

  meta = with lib; {
    description = "Formal Specifications for Verification and Synthesis";
    homepage = "https://github.com/VUISIS/formula-dotnet";
    license = licenses.mspl;
    maintainers = with maintainers; [ siraben ];
    platforms = platforms.unix;
  };
}
