#!/bin/sh
set -eu
root=/home/siraben/i686-iso-work/refresh-20261111
lane="$root/parallel/tlrender-cpp20-parent"
app="$root/tlrender-i686-sse2-utf8-result"
fixture=/nix/var/nix/builds/nix-3558329-1790592233/build/source/build/testdata/configs/context_test1
python3 - <<'PY'
import os
p='/nix/var/nix/builds/nix-3558329-1790592233/build/source/build/testdata/configs/context_test1'
assert os.stat(p).st_ino>2**32-1
for k,v in os.environ.items():
    if k.startswith(('CFLAGS','CXXFLAGS','CPPFLAGS','NIX_CFLAGS_COMPILE')):
        assert '_FILE_OFFSET_BITS' not in v and '_TIME_BITS' not in v,(k,v)
PY
/nix/store/49jmbfsrsp9iwilqhqnwi3y7dnlh38rj-gcc-wrapper-16.2.0/bin/g++ \
    -std=c++20 -O2 -Wall -Wextra -I"$app/include/tlRender" \
    -I/nix/store/q1bphnfq03q52nqmnbi1vb4apzd998ac-feather-tk-0.4.0/include \
    -I/nix/store/ifa1fa8nw2gwhip4mqb8cy10dx6jaa19-nlohmann_json-3.12.0/include \
    "$lane/fileinfo-consumer.cpp" -L"$app/lib" -ltlCore -Wl,-rpath,"$app/lib" \
    -o "$lane/fileinfo-consumer.i686"
size=$(python3 -c 'import os,sys; print(os.stat(sys.argv[1]).st_size)' "$fixture/config.ocio")
timeout 30 "$lane/fileinfo-consumer.i686" "$fixture" "$size"
readelf --dyn-syms --wide "$app/lib/libtlCore.so" > "$lane/tlcore-dynamic-symbols.txt"
python3 - <<'PY'
import json,re
from pathlib import Path
r=Path('/home/siraben/i686-iso-work/refresh-20261111');l=r/'parallel/tlrender-cpp20-parent'
s=(l/'tlcore-dynamic-symbols.txt').read_text()
assert 'readdir64@' in s and 'stat64@' in s
assert not re.search(r'\bUND readdir@',s)
(l/'fileinfo-passed.json').write_text(json.dumps({'passed':True,'scope':'installed SSE2-comparison tlCore high-inode API, NOT media/GUI/generic-CPU validation','artifact':str((r/'tlrender-i686-sse2-utf8-result').resolve()),'callerOffT':4,'callerTimeT':4,'wideLibraryImports':['readdir64','stat64']},indent=2)+'\n')
PY
