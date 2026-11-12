## qt6.qtbase: enable large-file ABI in qmake

Add _FILE_OFFSET_BITS=64 privately to the Unix qmake target. qmake's raw POSIX
stat calls bypass QtCore's large-file wrappers, so narrow ino_t can make file
installation fail with EOVERFLOW on i686 even when the file is tiny.

Keep QtCore's public ABI unchanged; do not inject the flag into all Qt users or
general stdenv. The definition is scoped by the tool's own CMake target, not a
hardcoded application hostPlatform guard that could be wrong for cross builds.

### Validation

- Full qt6.qtbase 6.12.0 builds pass on i686 and x86_64.
- Installed i686 qmake now imports stat64 (readelf verification).
- Exact installed-tool regression on a 7066-byte file, inode 4297357119:
  - Original qmake -install qinstall: exit 3, "Value too large for defined data type".
  - Patched qmake: exit 0, installed contents match the reference byte-for-byte.
- Original-source translation-unit probes also reproduce/fix the overflow.
- PyQt6 installation and Krita downstream rebuilds are still pending.
- No ARM/macOS/cross build validation claimed.

Nixpkgs and public GitHub keyword searches found no matching open fix. Qt Gerrit
requests returned HTTP 403, so a manual upstream duplicate check is advised.
Qt5's corresponding bootstrap-tool fix is a separate validated branch;
maintainers may prefer combining these version-specific changes.

```sh
nix-build . -A qt6.qtbase --argstr system i686-linux --option extra-platforms i686-linux
nix-build . -A qt6.qtbase --argstr system x86_64-linux
```

Evidence: `audit/qt6-qmake-install-regression/passed.json` and the corresponding
reproducer in the drafts/report branch. Focused code branch is based on
upstream a238bac4849a79e151329cdc51638d3bc7627c6c; builds used the integration
stack, not every other fix reverted.

Prepared with AI assistance; operator review required before submission.
