#!/bin/sh
set -eu
root=/home/siraben/i686-iso-work/refresh-20261111
tree="$root/focused-validation/opencolorio-filesystem"
test ! -e "$tree"
mkdir -p "$root/focused-validation"
git -C "$root/nixpkgs" worktree add --detach "$tree" 2939057da7a3499d9fad0847a7cba3b1d9f26a92
python3 "$root/run.py" opencolorio-focused-x86_64-build nix-build "$tree" -A opencolorio \
    --argstr system x86_64-linux --out-link "$root/opencolorio-focused-x86_64-result" \
    --keep-going --keep-failed --max-jobs 2 --cores 4 --max-silent-time 900
python3 - <<'PY'
import json
from pathlib import Path
r=Path('/home/siraben/i686-iso-work/refresh-20261111')
assert json.loads((r/'opencolorio-focused-x86_64-build.json').read_text())['status']=='passed'
output=str((r/'opencolorio-focused-x86_64-result').resolve(strict=True))
validated=str((r/'opencolorio-x86_64-public-metadata-result').resolve(strict=True))
(r/'parallel/minizip-public-validation/ocio-focused-x64-passed.json').write_text(json.dumps({'passed':True,'branch':'siraben/i686-opencolorio-filesystem-20261111','commit':'2939057da7a3499d9fad0847a7cba3b1d9f26a92','base':'a238bac4849a79e151329cdc51638d3bc7627c6c','system':'x86_64-linux','output':output,'validatedIntegrationOutput':validated,'sameOutput':output==validated},indent=2)+'\n')
print('PASS: focused OCIO filesystem branch builds on BASE for x86_64; matching integration output:', output==validated)
PY
