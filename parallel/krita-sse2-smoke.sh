#!/bin/sh
set -eu
root=/home/siraben/i686-iso-work/refresh-20261111
work="$root/parallel/krita-sse2-runtime"
app="$root/krita-i686-sse2-comparison-result"
test ! -e "$work"
mkdir -p "$work/home" "$work/cache" "$work/config"
export HOME="$work/home" XDG_CACHE_HOME="$work/cache" XDG_CONFIG_HOME="$work/config"
export QT_QPA_PLATFORM=offscreen
python3 "$root/run.py" krita-i686-sse2-version timeout 90 "$app/bin/krita" --version
python3 "$root/run.py" krita-i686-sse2-png-export timeout 180 "$app/bin/krita" \
    --nosplash --export --export-filename "$work/quadrants.png" "$root/audit/krita-quadrants.ppm"
identify "$work/quadrants.png"
convert "$work/quadrants.png" -alpha off -depth 8 "rgb:$work/quadrants.rgb"
nix-store -qR "$app" > "$work/closure.txt"
python3 - <<'PY'
import json, struct
from pathlib import Path
r=Path('/home/siraben/i686-iso-work/refresh-20261111');w=r/'parallel/krita-sse2-runtime'
png=(w/'quadrants.png').read_bytes()
assert png.startswith(b'\x89PNG\r\n\x1a\n')
assert struct.unpack('>II',png[16:24])==(4,4)
expected=bytes([255,0,0]*2+[0,255,0]*2)*2+bytes([0,0,255]*2+[255,255,255]*2)*2
assert (w/'quadrants.rgb').read_bytes()==expected, 'lossless quadrant pixels differ'
minizip=[x for x in (w/'closure.txt').read_text().splitlines() if '-minizip-ng-' in x]
(w/'passed.json').write_text(json.dumps({'passed':True,'scope':'SSE2-only diagnostic Krita artifact on native host, NOT generic CPU or complete GUI/plugin validation','application':str((r/'krita-i686-sse2-comparison-result').resolve()),'imageDimensions':[4,4],'pixelComparison':'all RGB bytes exact','minizipClosureEntries':minizip},indent=2)+'\n')
print('PASS: SSE2-only Krita version/export and exact lossless pixel smoke')
PY
