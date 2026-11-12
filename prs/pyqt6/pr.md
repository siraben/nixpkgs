## python3Packages.pyqt6: gate PDF bindings on QtWebEngine availability

Default optional PDF bindings to
`lib.meta.availableOn stdenv.hostPlatform qt6Packages.qtwebengine`.
Qt PDF is supplied by QtWebEngine, which is unavailable on i686. Preserve
explicit `withPdf` overrides and the enabled x86_64 default. This does not
port QtWebEngine or PDF rendering to i686.

### Validation

- PyQt6 6.11.0 builds and package import checks pass on i686 and x86_64,
  including the rebuild against repaired Qt6 qmake.
- Additional runtime imports of QML, Quick, Multimedia and WebSockets pass.
- Offscreen QLabel rendering and PNG output pass on both widths; screenshots
  were visually reviewed.
- QtPdf and QtPdfWidgets are absent on i686, present and importable on x86_64.
- Validation uses the integration stack, including separate Qt6 qmake
  large-inode and Qt Multimedia i686 repairs. This focused branch alone is
  not claimed to build i686 against otherwise unpatched BASE.
- No ARM, macOS, physical hardware, PDF-document rendering, multimedia playback
  or full Krita validation is claimed.

Evidence: `parallel/app-repairs/pyqt6-{i686,x86_64}-qmake-lfs.{json,log}`,
`pyqt6-{i686-linux,x86_64-linux}-runtime-smoke.{json,log}` and
`audit/pyqt6-*-smoke.png`. Reproducer: `pyqt-smoke.{nix,py}`.

```sh
nix-build . -A python3Packages.pyqt6 --argstr system i686-linux --option extra-platforms i686-linux
nix-build . -A python3Packages.pyqt6 --argstr system x86_64-linux
```

Prepared with AI assistance; operator review required before submission.
No PR opened automatically. Related QtWebEngine Darwin cleanup #538261 does
not change this PyQt expression; this is not a duplicate of that change.
