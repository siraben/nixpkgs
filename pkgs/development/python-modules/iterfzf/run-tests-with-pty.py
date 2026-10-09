"""Give the real fzf singleton-selection tests a controlling terminal."""

import errno
import fcntl
import os
import pty
import signal
import struct
import sys
import termios
import xml.etree.ElementTree as ET

report = os.path.abspath("pty-test-results.xml")
arguments = [*sys.argv[1:], f"--junitxml={report}"]

def timeout(_signum, _frame):
    raise TimeoutError("PTY pytest exceeded 120 seconds")

pid, master = pty.fork()
if pid == 0:
    os.environ["TERM"] = "xterm"
    os.execv(sys.executable, [sys.executable, *arguments])

# A headless builder has no window size to inherit.
fcntl.ioctl(master, termios.TIOCSWINSZ, struct.pack("HHHH", 24, 80, 0, 0))
signal.signal(signal.SIGALRM, timeout)
signal.alarm(120)
try:
    while True:
        try:
            data = os.read(master, 8192)
        except OSError as error:
            if error.errno == errno.EIO:
                break
            raise
        if not data:
            break
        sys.stdout.buffer.write(data)
        sys.stdout.buffer.flush()
    _, status = os.waitpid(pid, 0)
except BaseException:
    os.kill(pid, signal.SIGKILL)
    os.waitpid(pid, 0)
    raise
finally:
    signal.alarm(0)
    os.close(master)
exit_code = os.waitstatus_to_exitcode(status)
if exit_code == 0:
    suites = ET.parse(report).getroot().findall("testsuite")
    tests = sum(int(s.attrib["tests"]) for s in suites)
    failures = sum(int(s.attrib["failures"]) + int(s.attrib["errors"]) for s in suites)
    if tests == 0 or failures:
        raise RuntimeError("No passing pytest suite recorded")
    print(f"PTY pytest recorded {tests} tests, {failures} failures/errors", flush=True)
sys.exit(exit_code)
