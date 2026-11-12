#!/bin/sh
set -eu
root=/home/siraben/i686-iso-work/refresh-20261111
lane="$root/parallel/lo-font-cache-validation"
work="$lane/x64-runtime-smoke"
app="$root/libreoffice-x86_64-font-repairs-result"
test ! -e "$work"
mkdir -p "$work/home" "$work/cache" "$work/config"
export HOME="$work/home" XDG_CACHE_HOME="$work/cache" XDG_CONFIG_HOME="$work/config"
python3 "$root/run.py" libreoffice-x86_64-fonts-version timeout 90 "$app/bin/libreoffice" --headless --version
python3 "$root/run.py" libreoffice-x86_64-fonts-pdf-conversion timeout 180 \
    "$app/bin/libreoffice" "-env:UserInstallation=file://$work/profile" --headless \
    --convert-to pdf --outdir "$work" "$lane/font-smoke.fodt"
pdftotext "$work/font-smoke.pdf" "$work/font-smoke.txt"
python3 - <<'PY'
import json
from pathlib import Path
r=Path('/home/siraben/i686-iso-work/refresh-20261111')
w=r/'parallel/lo-font-cache-validation/x64-runtime-smoke'
assert (w/'font-smoke.pdf').read_bytes().startswith(b'%PDF-')
text=(w/'font-smoke.txt').read_text()
assert 'LibreOffice font repair validation' in text, text
assert 'Shared font mappings and the supported AFDKO driver.' in text, text
(w/'passed.json').write_text(json.dumps({'passed':True,'scope':'wrapped x86_64 version and headless FODT-to-PDF/text smoke; NOT an embedded-font/GUI/i686 claim','application':str((r/'libreoffice-x86_64-font-repairs-result').resolve()),'pdf':str(w/'font-smoke.pdf'),'text':text},indent=2)+'\n')
print('PASS: wrapped x86_64 version and headless PDF/text smoke')
PY
