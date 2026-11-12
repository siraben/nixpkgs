#!/usr/bin/env python3
"""Supply GLFW's display prerequisite; own and clean up a private Xvfb."""
import json
import os
from pathlib import Path
import select
import shutil
import subprocess

root = Path('/home/siraben/i686-iso-work/refresh-20261111')
work = root/'parallel/timeline-cli-xvfb'
work.mkdir(exist_ok=False)
xvfb = shutil.which('Xvfb')
assert xvfb, 'Xvfb required'
read_fd, write_fd = os.pipe()
results = []
with (work/'xvfb.log').open('wb') as server_log:
    server = subprocess.Popen([xvfb, '-displayfd', str(write_fd), '-screen', '0',
                               '1280x800x24', '-nolisten', 'tcp', '-ac'],
                              pass_fds=(write_fd,), stdout=server_log, stderr=server_log)
    os.close(write_fd)
    try:
        assert select.select([read_fd], [], [], 20)[0], 'Xvfb readiness timeout'
        display_number = os.read(read_fd, 64).decode().strip()
        assert display_number.isdigit(), ('Xvfb did not report a display', display_number)
        assert server.poll() is None, 'Xvfb exited before test'
        display = ':'+display_number
        for name, result, description in [
            ('tlplay', 'tlrender-i686-sse2-utf8-result', 'Example player application.'),
            ('djv', 'djv-i686-sse2-comparison-result', 'Playback and review image sequences.'),
        ]:
            home = work/name
            home.mkdir()
            env = dict(os.environ, HOME=str(home), XDG_CONFIG_HOME=str(home/'config'),
                       XDG_CACHE_HOME=str(home/'cache'), DISPLAY=display,
                       LIBGL_ALWAYS_SOFTWARE='1')
            env.pop('WAYLAND_DISPLAY', None)
            command = [str(root/result/'bin'/name), '--help']
            run = subprocess.run(command, env=env, capture_output=True, text=True, timeout=60)
            (work/(name+'.stdout')).write_text(run.stdout)
            (work/(name+'.stderr')).write_text(run.stderr)
            assert run.returncode == 1, (name,run.returncode,run.stdout,run.stderr)
            assert 'Usage:' in run.stdout and description in run.stdout, (name,run.stdout,run.stderr)
            results.append({'program':name,'artifact':str((root/result).resolve()),
                            'command':command,'expectedHelpExit':run.returncode,
                            'descriptionVerified':description})
        (work/'passed.json').write_text(json.dumps({'passed':True,'scope':'SSE2-only artifact CLI help under private Xvfb; NOT GUI playback or generic CPU validation','programs':results,'display':display},indent=2)+'\n')
        print('PASS: tlplay and DJV help exit/content with GLFW display prerequisite')
    finally:
        os.close(read_fd)
        if server.poll() is None:
            server.terminate()
            try:
                server.wait(timeout=10)
            except subprocess.TimeoutExpired:
                server.kill()
                server.wait(timeout=10)
