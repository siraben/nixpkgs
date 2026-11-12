## python3Packages.pyside6: omit unavailable optional web modules

Use `lib.meta.availableOn` to conditionally include optional QtWebEngine
bindings. On Linux QtWebView also uses QtWebEngine, so gate it by the backend's
availability. Preserve native WebView on macOS and all core bindings.

This restores i686 evaluation through LXQt → kguiaddons → PySide6. It does not
port Chromium/QtWebEngine to i686. Existing cross-build work in PR #526288 is
not duplicated; this change addresses native platform availability.

### Validation

- PySide6 6.12.0 builds/import checks pass on i686 and x86_64.
- Complete LXQt NixOS system builds on i686 (`lxqt-i686-attempt2.json`).
- Additional i686 generator/Qt Multimedia fixes were required and are separate
  branches; this focused branch was validated in the integration stack.
- Fresh LXQt live ISO boots under BIOS/QEMU TCG: Xorg, LXQt session/panel,
  PCManFM-Qt, QTerminal and 30-second stability checks pass; screenshot reviewed.
- No macOS build or installed-LXQt boot claimed.

```sh
nix-build . -A python3Packages.pyside6 --argstr system i686-linux --option extra-platforms i686-linux
nix-build . -A python3Packages.pyside6 --argstr system x86_64-linux
```

Prepared with AI assistance; operator review required before submission.
