import json
import os
from pathlib import Path
import shlex
import sys

mode = sys.argv[1]
assert mode in ("config", "pkgconfig")
for key, value in os.environ.items():
    if key.startswith(("NIX_CFLAGS_COMPILE", "CFLAGS", "CXXFLAGS", "CPPFLAGS")):
        assert "_FILE_OFFSET_BITS" not in value and "_TIME_BITS" not in value, (key, value)
cache = {}
for line in Path("CMakeCache.txt").read_text().splitlines():
    if line and not line.startswith(("#", "//")) and "=" in line:
        key, value = line.split("=", 1)
        cache[key.split(":", 1)[0]] = value
config_dir = cache.get("minizip-ng_DIR", "")
if mode == "pkgconfig":
    assert config_dir.endswith("-NOTFOUND"), config_dir
    assert cache.get("PC_minizip-ng_FOUND") == "1", cache.get("PC_minizip-ng_FOUND")
else:
    assert config_dir and not config_dir.endswith("-NOTFOUND"), config_dir
required = (
    "src/OpenColorIO/Platform.cpp",
    "src/OpenColorIO/OCIOZArchive.cpp",
    "src/apps/ocioarchive/main.cpp",
)
commands = json.loads(Path("compile_commands.json").read_text())
evidence = []
for suffix in required:
    candidates = [row for row in commands if row["file"].endswith("/" + suffix)]
    assert candidates, suffix
    for row in candidates:
        args = row.get("arguments") or shlex.split(row["command"])
        assert "-D_FILE_OFFSET_BITS=64" in args, (suffix, args)
        evidence.append({"file": suffix, "file_offset_bits": 64})
print(json.dumps({"discovery": mode, "commands": evidence,
                  "no_ambient_file_or_time_flags": True}, indent=2))
