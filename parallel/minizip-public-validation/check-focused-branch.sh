#!/bin/sh
set -eu
root=/home/siraben/i686-iso-work/refresh-20261111
tree="$root/focused-validation/minizip-ng"
test ! -e "$tree"
mkdir -p "$root/focused-validation"
git -C "$root/nixpkgs" worktree add --detach "$tree" 33c29fc6802cf6eed89d6c79c2cbcba0eb43af8c
for variant in normal compat; do
    expression="let p=import $tree {system=\"i686-linux\";}; in {normal=p.minizip-ng;compat=p.minizip-ng.override {enableCompat=true;};}"
    python3 "$root/run.py" "minizip-$variant-focused-i686" nix-build --expr "$expression" -A "$variant" \
        --out-link "$root/minizip-$variant-focused-i686-result" --keep-going --keep-failed \
        --max-jobs 2 --cores 4 --max-silent-time 900 \
        --option extra-platforms 'i686-linux x86_64-linux aarch64-linux armv7l-linux'
done
python3 - <<'PY'
import json
from pathlib import Path
r=Path('/home/siraben/i686-iso-work/refresh-20261111')
outputs={v:str((r/f'minizip-{v}-focused-i686-result').resolve(strict=True)) for v in ['normal','compat']}
validated={'normal':str((r/'minizip-i686-public-result').resolve(strict=True)), 'compat':str((r/'minizip-compat-i686-public-result').resolve(strict=True))}
for v in outputs:
    assert json.loads((r/f'minizip-{v}-focused-i686.json').read_text())['status']=='passed'
(r/'parallel/minizip-public-validation/focused-branch-passed.json').write_text(json.dumps({'passed':True,'branch':'siraben/i686-minizip-ng-20261111','commit':'33c29fc6802cf6eed89d6c79c2cbcba0eb43af8c','base':'a238bac4849a79e151329cdc51638d3bc7627c6c','outputs':outputs,'validatedIntegrationOutputs':validated,'sameOutputs':outputs==validated},indent=2)+'\n')
print('PASS: focused minizip branch builds independently; matching validated outputs:', outputs==validated)
PY
