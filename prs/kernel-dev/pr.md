## linux: retain architecture Makefile fragments in dev output

### Description of changes

Keep `Makefile*`, not only files named exactly `Makefile`, when pruning the
kernel development source tree. The x86 Makefile includes Makefile_32.cpu for
32-bit builds; pruning deletes that fragment and breaks external modules.

ZFS configure misleadingly reports missing CONFIG_MODULES because its probe
cannot run make. The retained build log identifies the actual failure:

```
arch/x86/Makefile_32.cpu: No such file or directory
No rule to make target .../arch/x86/Makefile_32.cpu
```

The kernel configuration does have CONFIG_MODULES=y. This fixes development
output packaging rather than changing kernel module support or ZFS detection.

### Validation

- Reproduced ZFS configure failure with the original kernel development output.
- Rebuilt Linux 6.18.63 and ZFS 2.4.4 successfully on i686 and x86_64.
- Both outputs contain a compiled zfs.ko.xz module.
- Modules were built, not loaded into the host kernel.
- i686 validation includes existing TCP_AO fix PR #558908 and the integration
  dependency fixes; this branch itself contains only the dev-output change.
- Full ISO build and boot checks are still pending.

```sh
nix-build --expr 'let p = import ./. { system = "i686-linux"; }; in p.linuxPackages.${p.zfs.kernelModuleAttribute}' --option extra-platforms i686-linux
nix-build --expr 'let p = import ./. { system = "x86_64-linux"; }; in p.linuxPackages.${p.zfs.kernelModuleAttribute}'
```

Prepared with AI assistance; operator review required before submission.
