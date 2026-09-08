{
  lib,
  stdenv,
  callPackage,
  makeWrapper,
  bash,
  cabextract,
  coreutils,
  curl,
  gawk,
  gnugrep,
  gnused,
  gnutar,
  gzip,
  p7zip,
  perl,
  unzip,
  which,
  zenity,
  unrar-free,
  versionCheckHook,
  runCommand,
  wineWow64Packages,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "winetricks";
  version = finalAttrs.src.version;

  src = (callPackage ./sources.nix { }).winetricks;

  buildInputs = [
    perl
    which
    makeWrapper
  ];

  makeFlags = [ "PREFIX=$(out)" ];

  doCheck = false; # requires "bashate"

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];

  postPatch = ''
    patchShebangs src/winetricks
    substituteInPlace src/winetricks \
      --replace-fail 'command -v unrar' 'command -v unrar-free' \
      --replace-fail 'w_try unrar' 'w_try unrar-free'
  '';

  postInstall =
    let
      runtimeDependencies = [
        bash
        cabextract
        coreutils
        curl
        gawk
        gnugrep
        gnused
        gnutar
        gzip
        p7zip
        perl
        unrar-free
        unzip
        which
        zenity
      ];
    in
    ''
      wrapProgram $out/bin/winetricks \
        --prefix PATH : "${lib.makeBinPath runtimeDependencies}" \
        --set WINETRICKS_LATEST_VERSION_CHECK "disabled" \
        --run ${lib.escapeShellArg ''
          # The GStreamer-enabled Wine package moves wrapped binaries to dot-prefixed names.
          # Tell Winetricks to inspect those ELF binaries instead of their shell wrappers.
          winetricks_find_wrapped_binary() {
            winetricks_wrapper="$(command -v "$1" 2>/dev/null || true)"
            if [ -n "$winetricks_wrapper" ]; then
              winetricks_wrapper="$(readlink -f "$winetricks_wrapper" 2>/dev/null || true)"
              winetricks_binary="$(dirname "$winetricks_wrapper")/.$(basename "$winetricks_wrapper")"
              if [ -x "$winetricks_binary" ]; then
                printf '%s\n' "$winetricks_binary"
              fi
            fi
          }

          if [ -z "''${WINE_BIN:-}" ]; then
            WINE_BIN="$(winetricks_find_wrapped_binary "''${WINE:-wine}")"
            [ -z "$WINE_BIN" ] || export WINE_BIN
          fi
          if [ -z "''${WINESERVER_BIN:-}" ]; then
            WINESERVER_BIN="$(winetricks_find_wrapped_binary "''${WINESERVER:-wineserver}")"
            [ -z "$WINESERVER_BIN" ] || export WINESERVER_BIN
          fi
          unset -f winetricks_find_wrapped_binary
          unset winetricks_wrapper winetricks_binary
        ''}
    '';

  passthru = {
    inherit (finalAttrs.src) updateScript;
    tests =
      lib.optionalAttrs
        (stdenv.hostPlatform.isLinux && (stdenv.hostPlatform.isx86_64 || stdenv.hostPlatform.isAarch64))
        {
          wow64 = runCommand "winetricks-wow64-test" { nativeBuildInputs = [ finalAttrs.finalPackage ]; } ''
            export HOME="$TMPDIR/home"
            export WINEPREFIX="$TMPDIR/prefix"
            export WINEDEBUG=-all
            export WINETRICKS_GUI=none
            mkdir -p "$HOME"

            mkdir -p "$TMPDIR/profile/bin"
            ln -s ${wineWow64Packages.stableFull}/bin/wine "$TMPDIR/profile/bin/wine"
            ln -s ${wineWow64Packages.stableFull}/bin/wineserver "$TMPDIR/profile/bin/wineserver"
            export PATH="$TMPDIR/profile/bin":${lib.makeBinPath [ wineWow64Packages.stableFull ]}:$PATH
            trap 'wineserver -k >/dev/null 2>&1 || true' EXIT
            if ! timeout 300 winetricks list-installed >stdout 2>stderr; then
              cat stdout stderr >&2
              exit 1
            fi

            grep -F "Wine's new wow64 mode" stderr
            if grep -E "Unknown file arch|WoW64 type could not be detected" stderr; then
              cat stderr >&2
              exit 1
            fi
            touch $out
          '';
        };
  };

  meta = {
    description = "Script to install DLLs needed to work around problems in Wine";
    mainProgram = "winetricks";
    license = lib.licenses.lgpl21;
    homepage = "https://github.com/Winetricks/winetricks";
    platforms = with lib.platforms; linux ++ darwin;
  };
})
