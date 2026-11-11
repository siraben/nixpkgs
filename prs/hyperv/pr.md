## nixos/installer: avoid Hyper-V modules on i686

Enable the graphical installer's Hyper-V guest support only on x86_64 and
AArch64, not all x86 systems. Likewise, only add hv_storvsc to all-hardware's
x86 module list on x86_64. VMware support remains enabled on i686.

The i686 ISO's initrd build fails because hv_balloon is unavailable; hv_storvsc
is also not present. Disabling unsupported Hyper-V integration avoids those
module requirements without weakening missing-module checks.

Validation:
- Full i686 Xfce ISO builds with this fix and the other integration fixes.
- x86_64 kernel, shrunk module tree, initrd and Hyper-V service derivations are
  identical before/after. The entire ISO derivation changes because it embeds
  the modified Nixpkgs source; this is not a whole-image equivalence claim.
- AArch64's existing enable condition remains unchanged; no ARM build run.
- Current-refresh boot tests are pending.

This focused branch is based on a238bac4849a79e151329cdc51638d3bc7627c6c and
contains only these two module guards. ISO validation was performed with the
complete integration stack, not this branch in isolation.

Prepared with AI assistance; operator review required before submission.
