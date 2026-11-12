#!/usr/bin/env python3
"""Private Xvfb with architecture-matched software GLX libraries."""
import json
import os
from pathlib import Path
import select
import shutil
import subprocess

root = Path('/home/siraben/i686-iso-work/refresh-20261111')
work = root/'parallel/timeline-cli-mesa'
work.mkdir(exist_ok=False)
mesa64 = root/'timeline-mesa64-result'
mesa32 = Path('/nix/store/rx63m5m9b8lm65zsy5dq7318apjyzgbr-mesa-26.3.0')
for mesa in (mesa64, mesa32):
    assert (mesa/'lib/libGLX_mesa.so.0').exists()
    assert (mesa/'lib/dri/swrast_dri.so').exists()
def graphics_env(base, mesa):
    env = dict(base, LD_LIBRARY_PATH=str(mesa/'lib'),
               LIBGL_DRIVERS_PATH=str(mesa/'lib/dri'),
               LIBGL_ALWAYS_SOFTWARE='1', GALLIUM_DRIVER='llvmpipe',
               __GLX_VENDOR_LIBRARY_NAME='mesa', LIBGL_DEBUG='verbose')
    env.pop('WAYLAND_DISPLAY', None)
    return env
read_fd, write_fd = os.pipe()
results = []
with (work/'xvfb.log').open('wb') as log:
    server = subprocess.Popen([shutil.which('Xvfb'), '-displayfd', str(write_fd),
                               '-screen', '0', '1280x800x24', '+extension', 'GLX',
                               '-nolisten', 'tcp', '-ac'], pass_fds=(write_fd,),
                              env=graphics_env(os.environ, mesa64), stdout=log, stderr=log)
    os.close(write_fd)
    try:
        assert select.select([read_fd], [], [], 20)[0], 'Xvfb readiness timeout'
        number = os.read(read_fd, 64).decode().strip()
        assert number.isdigit() and server.poll() is None, 'Xvfb startup failed'
        display = ':'+number
        for label, program, result, description, mesa in [
            ('tlplay-x64', 'tlplay', 'tlrender-focused-x86_64-result', 'Example player application.', mesa64),
            ('tlplay-i686', 'tlplay', 'tlrender-i686-sse2-utf8-result', 'Example player application.', mesa32),
            ('djv-i686', 'djv', 'djv-i686-sse2-comparison-result', 'Playback and review image sequences.', mesa32),
        ]:
            home = work/label
            home.mkdir()
            env = graphics_env(dict(os.environ, HOME=str(home),
                       XDG_CONFIG_HOME=str(home/'config'), XDG_CACHE_HOME=str(home/'cache'),
                       DISPLAY=display), mesa)
            command = [str(root/result/'bin'/program), '--help']
            run = subprocess.run(command, env=env, capture_output=True, text=True, timeout=90)
            (work/(label+'.stdout')).write_text(run.stdout)
            (work/(label+'.stderr')).write_text(run.stderr)
            row = {'program':program,'label':label,'artifact':str((root/result).resolve()),
                   'mesa':str(mesa.resolve()),'exitCode':run.returncode,
                   'helpVerified':run.returncode==1 and 'Usage:' in run.stdout and description in run.stdout}
            results.append(row)
            (work/'results.json').write_text(json.dumps(results,indent=2)+'\n')
            assert row['helpVerified'], (label,run.returncode,run.stdout,run.stderr)
        (work/'passed.json').write_text(json.dumps({'passed':True,'scope':'CLI help with software GLX, i686 artifacts SSE2-only; NOT media playback or generic CPU validation','programs':results,'display':display},indent=2)+'\n')
        print('PASS: native x64 control and i686 tlplay/DJV expected help with software GLX')
    finally:
        os.close(read_fd)
        if server.poll() is None:
            server.terminate()
            try:
                server.wait(timeout=10)
            except subprocess.TimeoutExpired:
                server.kill()
                server.wait(timeout=10)
