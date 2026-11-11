## nixos/installation-cd-graphical: avoid unavailable packages on 32-bit

Do not enable the graphical installer's QEMU guest agent on 32-bit platforms,
where the package is unavailable. Select Dillo instead of Firefox on 32-bit,
where Firefox is marked broken. Retain Firefox and the guest agent on 64-bit.

Validation:
- Reproduced both i686 evaluation blockers on the pinned upstream revision.
- Full i686 Xfce ISO builds with these guards and the integration's other fixes.
- Fresh live Xfce boot, offline installation, and disk-only installed Xfce boot verified under BIOS/QEMU TCG.
- No claim of ARM build or runtime validation.

This branch contains only the graphical-base package-selection guards on
upstream a238bac4849a79e151329cdc51638d3bc7627c6c. Successful ISO validation used
all integration fixes, including the separate Hyper-V guards, not this branch
in isolation.

Prepared with AI assistance; operator review required before submission.
