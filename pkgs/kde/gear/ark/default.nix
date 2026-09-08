{
  mkKdeDerivation,
  libarchive,
  libzip,
  python3,
  testers,
}:
let
  ark = mkKdeDerivation {
    pname = "ark";

    extraBuildInputs = [
      libarchive
      (libzip.override { withOpenssl = true; })
    ];

    passthru.tests.lzma-extraction = testers.runCommand {
      name = "ark-lzma-extraction";
      nativeBuildInputs = [
        ark
        python3
      ];
      env.LANG = "C.UTF-8";
      script = ''
        python3 - <<'PY'
        from pathlib import Path
        from zipfile import ZIP_LZMA, ZipFile

        payload = b"Ark can extract LZMA-compressed ZIP archives.\n"
        Path("expected").write_bytes(payload)
        with ZipFile("archive.zip", "w", compression=ZIP_LZMA) as archive:
            archive.writestr("payload.txt", payload)
        PY

        mkdir extracted
        # Ark displays extraction errors in a dialog even in batch mode.
        HOME="$TMPDIR" QT_QPA_PLATFORM=offscreen \
          timeout 30 ark --batch --destination extracted archive.zip
        cmp expected extracted/payload.txt
        touch "$out"
      '';
    };

    meta.mainProgram = "ark";
  };
in
ark
