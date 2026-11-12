#!/usr/bin/env python3
"""CLI help smoke: these upstream programs intentionally return 1 for --help."""
import json
import os
from pathlib import Path
import subprocess

root = Path('/home/siraben/i686-iso-work/refresh-20261111')
work = root/'parallel/timeline-cli-smoke'
work.mkdir(exist_ok=False)
results = []
for name, result, description in [
    ('tlplay', 'tlrender-i686-sse2-utf8-result', 'Example player application.'),
    ('djv', 'djv-i686-sse2-comparison-result', 'Playback and review image sequences.'),
]:
    home = work/name
    home.mkdir()
    env = dict(os.environ, HOME=str(home), XDG_CONFIG_HOME=str(home/'config'),
               XDG_CACHE_HOME=str(home/'cache'))
    env.pop('DISPLAY', None)
    command = [str(root/result/'bin'/name), '--help']
    run = subprocess.run(command, env=env, capture_output=True, text=True, timeout=60)
    (work/(name+'.stdout')).write_text(run.stdout)
    (work/(name+'.stderr')).write_text(run.stderr)
    assert run.returncode == 1, (name,run.returncode,run.stdout,run.stderr)
    assert 'Usage:' in run.stdout and description in run.stdout, (name,run.stdout,run.stderr)
    results.append({'program':name,'artifact':str((root/result).resolve()),
                    'command':command,'expectedHelpExit':run.returncode,
                    'descriptionVerified':description})
(work/'passed.json').write_text(json.dumps({'passed':True,'scope':'SSE2-only artifacts CLI help, no X11 display; NOT GUI, media playback or generic CPU validation','programs':results},indent=2)+'\n')
print('PASS: tlplay and DJV expected help exit/content, not GUI/media validation')
