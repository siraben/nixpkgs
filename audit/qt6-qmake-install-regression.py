#!/usr/bin/env python3
"""Compare installed qmake binaries on a tiny real high-inode reference."""
import json
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parent
source = Path('/nix/var/nix/builds/nix-1670704-3589367345/build/libreoffice-26.8.0.3/README.md')
stat = source.stat()
assert stat.st_ino > 2**32 - 1, stat.st_ino
assert 0 < stat.st_size < 1024 * 1024, stat.st_size
case = root / 'qt6-qmake-install-regression'
case.mkdir(exist_ok=False)
results = {'source': str(source), 'inode': stat.st_ino, 'size': stat.st_size}
for label, binary in [
    ('baseline', '/nix/store/23w03xfva5z5gw0h4jsvgia19l0izg3q-qtbase-6.12.0/bin/qmake'),
    ('fixed', '/nix/store/4vm4qwq4fr65z9ffafrgk9i40kwgvcp4-qtbase-6.12.0/bin/qmake'),
]:
    destination = case / (label + '-README.md')
    command = [binary, '-install', 'qinstall', str(source), str(destination)]
    result = subprocess.run(command, capture_output=True, text=True, timeout=30)
    (case / (label + '.log')).write_text(result.stdout + result.stderr)
    results[label] = {'command': command, 'exitCode': result.returncode,
                      'output': result.stdout + result.stderr}
    if label == 'baseline':
        assert result.returncode != 0, results
        assert 'Value too large for defined data type' in results[label]['output'], results
    else:
        assert result.returncode == 0, results
        assert destination.read_bytes() == source.read_bytes()
(case / 'passed.json').write_text(json.dumps(results, indent=2) + '\n')
print(json.dumps(results, indent=2))
