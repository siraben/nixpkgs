## qt5.qtbase: enable large-file ABI in bootstrap qmake

Define _FILE_OFFSET_BITS=64 for Unix bootstrap qmake and all of its private
bootstrap Qt objects via EXTRA_CPPFLAGS. This does not modify shared QtCore's
public ABI or general stdenv flags.

The bootstrap configuration does not enable Qt's usual large-file wrappers.
Its readdir stops with EOVERFLOW when encountering an inode number above
UINT32_MAX. The source directory name need not match qtbase.pro, so auto-
detection requires enumeration. When that fails, qmake tries to parse the
directory as a file and reports "file to open is a directory". This can happen
with tiny files: file size is not the trigger.

### Validation

- Baseline Qt5 build fails during bootstrap project discovery on i686.
- A minimal probe using the original Qt5 bootstrap platform headers reproduces
  narrow readdir's EOVERFLOW on the actual build filesystem; LFS resolves it.
- Full qt5.qtbase 5.15.19 builds pass on i686 and x86_64.
- Installed i686 qmake imports readdir64 and stat64, verified with readelf.
- Installed qmake discovers an intentionally mismatched directory/project name
  and generates its Makefile successfully.
- No shared Qt ABI change or cross/ARM build validation claimed.

The Unix bootstrap make template applies to the tool's build platform rather
than incorrectly guarding only the eventual application's hostPlatform.
EXTRA_CPPFLAGS is used because Makefile.unix later assigns CPPFLAGS.

Nixpkgs keyword searches found no matching open fix. Qt Gerrit requests were
blocked with HTTP 403; a manual upstream duplicate check is still advised.
Qt6's analogous private-tool repair is a separate branch under validation;
maintainers may prefer combining the two version-specific changes.

```sh
nix-build . -A qt5.qtbase --argstr system i686-linux --option extra-platforms i686-linux
nix-build . -A qt5.qtbase --argstr system x86_64-linux
```

Focused branch on a238bac4849a79e151329cdc51638d3bc7627c6c; validation used the
integration stack. Krita still has other dependency fixes under validation.

Prepared with AI assistance; operator review required before submission.
