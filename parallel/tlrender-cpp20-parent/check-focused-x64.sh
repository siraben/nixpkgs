#!/bin/sh
set -eu
root=/home/siraben/i686-iso-work/refresh-20261111
tree="$root/focused-validation/tlrender-utf8"
test ! -e "$tree"
mkdir -p "$root/focused-validation"
git -C "$root/nixpkgs" worktree add --detach "$tree" 05597ea92fa8c8a3957ea8ac54273a29d62bfdb9
python3 "$root/run.py" tlrender-focused-x86_64-build nix-build "$tree" -A tlrender \
    --argstr system x86_64-linux --out-link "$root/tlrender-focused-x86_64-result" \
    --keep-going --keep-failed --max-jobs 2 --cores 4 --max-silent-time 900
python3 - <<'PY'
import json
from pathlib import Path
r=Path('/home/siraben/i686-iso-work/refresh-20261111')
assert json.loads((r/'tlrender-focused-x86_64-build.json').read_text())['status']=='passed'
output=str((r/'tlrender-focused-x86_64-result').resolve(strict=True))
validated=str((r/'tlrender-x86_64-utf8-result').resolve(strict=True))
(r/'parallel/tlrender-cpp20-parent/focused-x64-passed.json').write_text(json.dumps({'passed':True,'scope':'focused BASE-only x86_64 build, not upstream GUI suite or generic i686','branch':'siraben/i686-tlrender-utf8-20261111','commit':'05597ea92fa8c8a3957ea8ac54273a29d62bfdb9','base':'a238bac4849a79e151329cdc51638d3bc7627c6c','output':output,'integrationOutput':validated,'sameOutput':output==validated},indent=2)+'\n')
PY
