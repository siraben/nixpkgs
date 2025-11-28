# MMIX Cross-Compilation Support in Nixpkgs

## Overview

This document details the work done to enable cross-compilation for the MMIX architecture (mmix-unknown-mmixware) in nixpkgs. MMIX is an educational 64-bit RISC architecture designed by Donald Knuth.

## Current Status

### Successfully Building
- ✅ **GNU Hello** (`pkgsCross.mmix.hello`) - Successfully builds and demonstrates basic cross-compilation
- ✅ **newlib** - C library with extensive POSIX stub additions
- ✅ **binutils** (in progress, dependencies building)
- ✅ **gcc** - Cross-compiler
- ✅ **pcre2** - With waitpid() stub
- ✅ **gmp** - GNU Multiple Precision library
- ✅ **Lua interpreters** (`pkgsCross.mmix.lua{5_1,5_2,5_3,5_4}`, the `compat` variants, and the default `lua`) - All four upstream releases build statically; Lua 5.4 uses the MMIX signal stub while older versions work unmodified once the newlib stubs are in place
- ✅ **zlib** (`pkgsCross.mmix.zlib`) - Compression library builds without extra dependencies
- ✅ **ncurses 6.5** (`pkgsCross.mmix.ncurses`) - Static-only build with wide-character/progs/tests disabled and configure cache overrides so termios can stand in for the missing `sgtty`
- ✅ **readline 8.3** (`pkgsCross.mmix.readline`) - Links against the static ncurses build with MMIX-specific CFLAGS and a patch that falls back to termios when `sgtty.h` is unavailable

### In Progress
- 🔄 **binutils** - Builds progressing, blocked by coreutils
- 🔄 **coreutils** - Needs additional time-related types (sbintime_t) and SSP support
- 🔄 **bash** - Now reaches the main build but fails because newlib lacks `sys/ioctl.h`, `struct winsize`, and job-control helpers (`sigblock`, `sigsetmask`, `WIFCONTINUED`, etc.)

### Not Yet Attempted
- ❌ **Full GNU toolchain** - May need additional work
- ❌ **Complex applications** - Unknown compatibility

## Architecture Details

- **Target Triple**: `mmix-unknown-mmixware`
- **C Library**: newlib 4.5.0.20241231
- **Compiler**: GCC 14.3.0
- **Binutils**: 2.44
- **Word Size**: 64-bit
- **Endianness**: Big-endian
- **System**: mmixware (minimal embedded environment)

## Changes Made

### 1. newlib Patches (`pkgs/by-name/ne/newlib/`)

#### File: `package.nix`
**Changes:**
- Added conditional patches for MMIX target
- Added `postBuild` hook to manually compile new stub functions
- Updated comments to reflect new functionality

**Key sections:**
```nix
++ lib.optionals (stdenvNoLibc.targetPlatform.parsed.cpu.name == "mmix") [
  # Add POSIX stub functions for MMIX/mmixware
  ./patches/newlib-mmix-rlimit.patch
];

postBuild = lib.optionalString (stdenvNoLibc.targetPlatform.parsed.cpu.name == "mmix") ''
  echo "Manually compiling POSIX stub functions for MMIX..."
  cd mmix-unknown-mmixware/newlib
  CFLAGS="-DHAVE_CONFIG_H -I. -Ilib -I../../newlib/libc/sys/mmixware -I../../newlib/libc/include -I.. -DPACKAGE_NAME=\"newlib\" -DPACKAGE_TARNAME=\"newlib\" -DPACKAGE_VERSION=\"4.5.0\" -g -O2"
  mmix-unknown-mmixware-gcc $CFLAGS -c -o libc/sys/mmixware/libc_a-getprogname.o ../../newlib/libc/sys/mmixware/getprogname.c
  mmix-unknown-mmixware-gcc $CFLAGS -c -o libc/sys/mmixware/libc_a-getrlimit.o ../../newlib/libc/sys/mmixware/getrlimit.c
  mmix-unknown-mmixware-gcc $CFLAGS -c -o libc/sys/mmixware/libc_a-signal.o ../../newlib/libc/sys/mmixware/signal.c
  mmix-unknown-mmixware-gcc $CFLAGS -c -o libc/sys/mmixware/libc_a-dirent.o ../../newlib/libc/sys/mmixware/dirent.c
  mmix-unknown-mmixware-gcc $CFLAGS -c -o libc/sys/mmixware/libc_a-mknod.o ../../newlib/libc/sys/mmixware/mknod.c
  mmix-unknown-mmixware-ar r libc.a libc/sys/mmixware/libc_a-getprogname.o libc/sys/mmixware/libc_a-getrlimit.o libc/sys/mmixware/libc_a-signal.o libc/sys/mmixware/libc_a-dirent.o libc/sys/mmixware/libc_a-mknod.o
  mmix-unknown-mmixware-ranlib libc.a
  cd ../..
'';
```

#### File: `patches/newlib-mmix-rlimit.patch` (415 lines)

**New Files Added:**
1. **`newlib/libc/sys/mmixware/getprogname.c`**
   - Implements: `getprogname()`, `setprogname()`, `getexecname()`
   - Purpose: Program name management for gnulib compatibility

2. **`newlib/libc/sys/mmixware/getrlimit.c`**
   - Implements: `getrlimit()`, `setrlimit()`
   - Purpose: Resource limit queries (stubs returning reasonable defaults)
   - Limits defined: RLIMIT_NOFILE, RLIMIT_STACK, RLIMIT_DATA, RLIMIT_AS, RLIMIT_CORE, RLIMIT_CPU, RLIMIT_FSIZE

3. **`newlib/libc/sys/mmixware/signal.c`**
   - Implements: `sigaddset()`, `sigdelset()`, `sigemptyset()`, `sigfillset()`, `sigismember()`, `raise()`
   - Purpose: Signal handling functions (real functions instead of macros to avoid gnulib conflicts)
   - Note: `raise()` is a no-op stub returning 0

4. **`newlib/libc/sys/mmixware/dirent.c`**
   - Implements: `opendir()`, `readdir()`, `closedir()`, `rewinddir()`
   - Purpose: Directory operations (stubs for bash/configure scripts)
   - All return errors (ENOSYS)

5. **`newlib/libc/sys/mmixware/mknod.c`**
   - Implements: `mknod()`, `mkfifo()`
   - Purpose: Special file creation (stubs for bash)
   - Both return errors (ENOSYS)

6. **`newlib/libc/sys/mmixware/sys/dirent.h`**
   - Defines: `DIR` structure, `struct dirent`, `NAME_MAX`
   - Purpose: Directory operation types

7. **`newlib/libc/sys/mmixware/sys/socket.h`**
   - Defines: `socklen_t` type
   - Purpose: Socket length type for configure scripts

**Modified Files:**
1. **`newlib/libc/include/stdlib.h`**
   - Added declarations for `getprogname()`, `setprogname()`, `getexecname()`

2. **`newlib/libc/include/sys/resource.h`**
   - Added `rlim_t` typedef
   - Added `struct rlimit` definition
   - Added RLIMIT_* constants
   - Added `getrlimit()` and `setrlimit()` declarations

3. **`newlib/libc/include/sys/signal.h`**
   - Modified to exclude MMIX from macro-based signal function definitions
   - Changed `#if !defined(__CYGWIN__) && !defined(__rtems__)` to include `&& !defined(__mmix__)`

4. **`newlib/libc/sys/mmixware/wait.c`**
   - Added `waitpid()` implementation (stub returning ENOSYS)

5. **`newlib/libc/sys/mmixware/Makefile.inc`**
   - Added new source files to build list

6. **`newlib/Makefile.in`**
   - Added new source files to mmixware file list

### 2. ncurses (`pkgs/development/libraries/ncurses/default.nix`)

**Changes:**
- Permanently disable shared objects, program utilities, and the test suite when the host CPU is MMIX, and force the build into static-only mode (`configureFlags`, `postInstall`)
- Inject cache variables so `configure` never tries to use `sgtty` (`cf_cv_have_sgtty_h=no`, `ac_cv_header_sgtty_h=no`) and always pretends `termios.h` plus `tcgetattr` are present (`ac_cv_header_termios_h=yes`, `cf_cv_have_tcgetattr=yes`)
- Fake out pkg-config wiring so `.pc` files are kept even though the `tic` utilities are stripped from the build (avoids broken symlinks caused by the wide-character conditional)
- Add a small `postPatch` tweak that inserts `#include <stdbool.h>` in `curses.h` so the stripped-down MMIX libc headers do not cause compile failures

**Verification:**
- `NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nix build .#pkgsCross.mmix.ncurses -L --impure`
- Result lives at `/nix/store/zylmgg8jbzx96d8b4nqp6sz06h93ylvs-ncurses-mmix-unknown-mmixware-6.5`

### 3. readline (`pkgs/development/libraries/readline/8.3.nix`)

**Changes:**
- Force static builds (`--enable-static --disable-shared`) and keep the `.a` outputs by setting `dontDisableStatic` when `hostPlatform.parsed.cpu.name == "mmix"`
- Pass cache overrides so termios is picked and `sgtty` is never probed (`ac_cv_header_termios_h=yes`, `ac_cv_header_sgtty_h=no`)
- Add `CFLAGS` shim `-DTERMIOS_TTY_DRIVER` which matches the patch below and gives readline a clean escape hatch when `sgtty.h` is missing
- New patch `pkgs/development/libraries/readline/no-sgtty-mm.patch`:
  - Guard `rltty.h` so it falls back to termios instead of including `<sgtty.h>`
  - Provide a private `struct winsize` when the system headers do not define one
- Ensured pkg-config metadata stays in the `-dev` output thanks to the extra copy step in `postInstall`

**Verification:**
- `NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nix build .#pkgsCross.mmix.readline -L --impure`
- Symlink `result -> /nix/store/qhw0mc1vj6gwah99j77339jjp76bgp4y-readline-mmix-unknown-mmixware-8.3p1`

### 4. Bash Patches (`pkgs/shells/bash/`)

#### File: `5.nix`
**Changes:**
- Added a MMIX-specific patch stack:
  - `gethostname-mmix.patch` – fixes the signature mismatch with newlib (`size_t` instead of `int`) in `externs.h`
  - `no-sgtty-mm.patch` – drops all `sgtty` use, adds a private `struct winsize`, and will eventually guard the remaining `<sys/ioctl.h>` include once a stub header exists
  - `no-network-stub.patch` – includes `<bashintl.h>`/`<shell.h>` even if networking is disabled so the stub `netopen()` can call `internal_error`
  - `command-bashtypes-mm.patch` – makes sure `command.h` pulls in `bashtypes.h` so `pid_t` is defined under newlib
- MMIX builds now pass `ac_cv_header_sys_ioctl_h=no` so configure stops enabling TTY ioctls that newlib does not provide

**Current Status:**
- `ncurses`/`readline` prerequisites link fine, but `bash` still fails while compiling `lib/sh/winsize.c`, `execute_cmd.c`, and `jobs.h`. The remaining blockers are:
  - No `<sys/ioctl.h>` – we need at least a stub header in newlib so `struct winsize`/`TIOCGWINSZ` references compile
  - Missing job-control helpers (`sigblock`, `sigsetmask`, and the `wait.h` macros such as `WIFCONTINUED`)
  - No implementations for the signals/wait APIs that the shell relies on
- Once those pieces exist in `newlib`, the current patches should let bash build completely static for MMIX.

### 5. GNU Hello Patches (`pkgs/by-name/he/hello/`)

#### File: `package.nix`
**Changes:**
- Added MMIX-specific compiler flag to inform gnulib that getprogname is available

```nix
env = lib.optionalAttrs stdenv.hostPlatform.isDarwin {
  NIX_LDFLAGS = "-liconv";
} // lib.optionalAttrs (stdenv.hostPlatform.parsed.cpu.name == "mmix") {
  # newlib for MMIX provides getprogname, inform gnulib
  NIX_CFLAGS_COMPILE = "-DHAVE_GETPROGNAME=1";
};
```

## Technical Challenges Encountered

### 1. Missing POSIX Functions in newlib
**Problem**: MMIX's newlib implementation lacks many POSIX functions that modern software expects.

**Solution**: Added stub implementations that:
- Return ENOSYS (function not implemented) for operations that can't work on embedded systems
- Return reasonable defaults for query operations (like getrlimit)
- Provide minimal type definitions for configure scripts

**Examples**:

### 6. Lua Interpreters (`pkgs/development/interpreters/lua-5/`)

- The MMIX-only signal shim (`mmix-no-signal.patch`) is now applied only when the interpreter version is ≥ 5.4. Older releases no longer see the patch (their sources differ around the signal handling block), so 5.1/5.2/5.3 can reuse the stock tree.
- With the newlib stubs in place, every stock Lua derivation cross-builds and runs under the simulator:
  - `pkgsCross.mmix.lua5_4` and `pkgsCross.mmix.lua5_4_compat`
  - `pkgsCross.mmix.lua5_3`, `pkgsCross.mmix.lua5_3_compat`, and `pkgsCross.mmix.lua`
  - `pkgsCross.mmix.lua5_2`, `pkgsCross.mmix.lua5_2_compat`
  - `pkgsCross.mmix.lua5_1`
- Verification: `nix shell nixpkgs#mmixware -c mmix $(nix build ... --print-out-paths)/bin/lua -v`
- `getrlimit()`: Returns hard-coded limits suitable for embedded systems
- `waitpid()`: Returns ENOSYS (no process management on MMIX)
- `opendir()`: Returns NULL with ENOSYS (no filesystem support)

### 2. Macro vs Function Conflicts
**Problem**: Newlib originally defined signal functions (`sigaddset`, etc.) as macros. When gnulib tries to provide replacements, the macros expand inside function declarations, causing syntax errors.

**Error Example**:
```
./signal.h:824:1: error: expected identifier or '(' before 'const'
  824 | _GL_FUNCDECL_SYS (sigismember, int, (const sigset_t *set, int sig),
```

**Solution**:
1. Modified `sys/signal.h` to exclude MMIX from macro definitions
2. Implemented proper functions in `signal.c`
3. Functions provide real implementations with error checking

### 3. Type Mismatches
**Problem**: Different type signatures between newlib and application expectations.

**Examples**:
- `gethostname()`: bash expected `int` for length, newlib uses `size_t`
- `mkfifo()`: Conflicting declarations between newlib and bash

**Solutions**:
- Patched bash to use correct POSIX signature
- Added proper function declarations in newlib headers

### 4. Build System Issues
**Problem**: Newlib's build system didn't pick up new source files from patches.

**Solution**: Added `postBuild` hook to manually compile new object files and add them to libc.a:
```bash
mmix-unknown-mmixware-gcc $CFLAGS -c -o libc/sys/mmixware/libc_a-<file>.o ...
mmix-unknown-mmixware-ar r libc.a libc/sys/mmixware/libc_a-<file>.o ...
mmix-unknown-mmixware-ranlib libc.a
```

### 5. Header File Precedence
**Problem**: Generic `sys/dirent.h` was being included instead of MMIX-specific version.

**Solution**: Added MMIX sys include directory earlier in include path:
```bash
-I../../newlib/libc/sys/mmixware -I../../newlib/libc/include
```

## Build Instructions

### Building GNU Hello for MMIX

```bash
cd /path/to/nixpkgs
NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nix build .#pkgsCross.mmix.hello --impure -L
```

**Expected Output**: Successfully builds hello binary for MMIX architecture.

### Testing the Build

The built binary will be in:
```bash
./result/bin/hello
```

**Note**: This is a cross-compiled binary for MMIX and cannot run directly on x86_64. You would need an MMIX simulator like `mmix` from the MMIXware package to execute it.

### Building Binutils (In Progress)

```bash
NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nix build .#pkgsCross.mmix.binutils --impure -L --keep-going
```

**Current Status**: Most dependencies build, but coreutils needs additional support.

## Remaining TODOs

### High Priority
1. **Add sbintime_t and related types** for coreutils
   - Location: `newlib/libc/include/sys/time.h` or new header
   - Types needed: `sbintime_t`, related SBT_* macros
   - Functions: `sbttoms()`, `mstosbt()`, etc.

2. **Add SSP (Stack Smashing Protection) headers**
   - Location: Need to create `ssp.h` or disable SSP for MMIX
   - Alternative: Patch coreutils to disable SSP for MMIX

3. **Provide a static-only ncurses/readline stack**
   - ncurses’ configure currently aborts with “Shared libraries are not supported in this version”.
   - Needed so bash/readline (and other CLI tools) can link on MMIX.

4. **Complete binutils build**
   - Depends on fixing coreutils
   - May reveal additional missing functions

### Medium Priority
5. **Test hello binary on MMIX simulator**
   - Install MMIXware toolchain
   - Run `mmix hello` and verify output

6. **Document known limitations**
   - List POSIX functions that cannot work on MMIX
   - Document which stubs return errors vs fake success

7. **Consider upstreaming patches**
   - newlib changes could benefit other MMIX users
   - Coordinate with newlib maintainers

### Low Priority
8. **Optimize stub implementations**
   - Some stubs could provide more realistic behavior
   - Example: `waitpid()` could track a fake process list

9. **Add more POSIX compatibility**
   - Network functions (socket, bind, etc.)
   - More complete time support
   - File locking primitives

10. **Test more packages**
   - Try building: gawk, sed, grep natively for MMIX
   - Document which packages work out of the box

## Function Reference

### Resource Limits (`getrlimit.c`)

| Function | Behavior | Return Value |
|----------|----------|--------------|
| `getrlimit()` | Returns hard-coded limits | 0 on success, -1 on invalid resource |
| `setrlimit()` | Always fails (not permitted) | -1 with errno=EPERM |

**Limits Provided:**
- `RLIMIT_NOFILE`: 256 file descriptors
- `RLIMIT_STACK`: 1 MB stack size
- `RLIMIT_DATA/AS`: RLIM_INFINITY (unlimited)
- `RLIMIT_CORE`: 0 (core dumps disabled)
- `RLIMIT_CPU/FSIZE`: RLIM_INFINITY

### Program Name (`getprogname.c`)

| Function | Behavior |
|----------|----------|
| `getprogname()` | Returns static program name (default: "mmix-program") |
| `setprogname()` | Sets program name (stored in static variable) |
| `getexecname()` | Alias for `getprogname()` |

### Signal Handling (`signal.c`)

| Function | Behavior | Return Value |
|----------|----------|--------------|
| `sigaddset()` | Adds signal to set | 0 or -1 on NULL |
| `sigdelset()` | Removes signal from set | 0 or -1 on NULL |
| `sigemptyset()` | Clears signal set | 0 or -1 on NULL |
| `sigfillset()` | Fills signal set | 0 or -1 on NULL |
| `sigismember()` | Tests if signal in set | 1/0 or -1 on NULL |
| `raise()` | No-op (signals not supported) | 0 (success) |

### Directory Operations (`dirent.c`)

| Function | Behavior | Return Value |
|----------|----------|--------------|
| `opendir()` | Stub (not supported) | NULL with errno=ENOSYS |
| `readdir()` | Stub (not supported) | NULL with errno=ENOSYS |
| `closedir()` | Stub (not supported) | -1 with errno=ENOSYS |
| `rewinddir()` | No-op | void |

### File Creation (`mknod.c`)

| Function | Behavior | Return Value |
|----------|----------|--------------|
| `mknod()` | Stub (not supported) | -1 with errno=ENOSYS |
| `mkfifo()` | Stub (not supported) | -1 with errno=ENOSYS |

### Process Control (`wait.c`)

| Function | Behavior | Return Value |
|----------|----------|--------------|
| `waitpid()` | Stub (no process management) | -1 with errno=ENOSYS |

## Known Issues

### 1. No Real Directory Support
**Impact**: Programs that need to traverse directories will fail at runtime.

**Workaround**: None - MMIX doesn't have a filesystem in the traditional sense.

### 2. No Signal Support
**Impact**: Signal-based IPC and error handling won't work.

**Workaround**: `raise()` returns success to allow programs to continue, but actual signal delivery doesn't happen.

### 3. No Process Management
**Impact**: Fork, exec, and wait operations don't work.

**Workaround**: Stubs return errors, so programs that check return values will handle gracefully.

### 4. Limited Time Support
**Impact**: Some time-related functions (sbintime_t) not yet implemented.

**Status**: Blocking coreutils build.

### 5. No Network Support
**Impact**: Socket operations not available.

**Status**: Only `socklen_t` type defined for configure script compatibility.

## References

### MMIX Architecture
- **MMIX Homepage**: https://mmix.cs.hm.edu/
- **The Art of Computer Programming**: Vol 1, Fascicle 1 (MMIX)
- **MMIXware**: https://github.com/ascherer/mmixware

### Newlib Documentation
- **Newlib Homepage**: https://sourceware.org/newlib/
- **Newlib Repository**: https://sourceware.org/git/newlib-cygwin.git
- **MMIX Port**: Contributed by Hans-Peter Nilsson

### Related Work
- **Gentoo MMIX**: Similar patches for Gentoo Linux
- **ARM Embedded Toolchain**: newlib-nano configuration reference

## Development Notes

### Debugging Tips

1. **Check build logs**:
```bash
nix log /nix/store/<hash>-<package>-mmix-unknown-mmixware-<version>.drv
```

2. **Keep intermediate build results**:
```bash
nix build --keep-failed .#pkgsCross.mmix.hello
# Check /tmp/nix-build-*
```

3. **Test individual packages**:
```bash
NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nix build .#pkgsCross.mmix.<package> --impure -L
```

4. **Check newlib installation**:
```bash
ls -R /nix/store/*-newlib-mmix-unknown-mmixware-*/mmix-unknown-mmixware/
```

### Common Error Patterns

**"undefined reference to X"**
- Missing function in newlib
- Add stub implementation to appropriate mmixware file
- Update Makefile.inc and Makefile.in
- Add to postBuild hook

**"conflicting types for X"**
- Type mismatch between newlib and application
- Check POSIX specification for correct signature
- Patch either newlib headers or application

**"#error <X> not supported"**
- Missing header file
- Create minimal version in `newlib/libc/sys/mmixware/sys/`
- Ensure it's included in patch

**"unknown type name X"**
- Missing type definition
- Add typedef to appropriate header
- Consider adding to `sys/types.h` or create new header

## Commit Messages

When committing these changes, use descriptive commit messages:

```
newlib: add POSIX stub functions for MMIX/mmixware

Add stub implementations of POSIX functions needed for cross-compiling
common GNU tools to MMIX architecture:

- Resource limits (getrlimit, setrlimit)
- Program name management (getprogname, setprogname)
- Signal handling (signal set operations, raise)
- Directory operations (opendir, readdir, closedir)
- File creation (mknod, mkfifo)
- Process control (waitpid)

These stubs allow configure scripts and gnulib-based programs to compile,
though most operations return ENOSYS at runtime since MMIX doesn't have
a traditional operating system.
```

```
bash: fix gethostname signature for MMIX

Change gethostname declaration to use size_t for the buffer length
parameter instead of int, matching the POSIX standard and newlib's
declaration for MMIX.
```

```
hello: inform gnulib of getprogname availability on MMIX

Set HAVE_GETPROGNAME=1 when building for MMIX to tell gnulib that
the function is provided by newlib, avoiding duplicate definitions.
```

## License

The newlib patches inherit newlib's licensing (mixture of BSD-style licenses, see newlib COPYING files).
The bash patch is derived from bash source (GPLv3+).
The hello package changes follow nixpkgs licensing (MIT).

## Contributors

- Initial MMIX newlib port: Hans-Peter Nilsson
- POSIX stub extensions: [Your contribution]

## Last Updated

2025-11-22

## Version History

- **v1 (2025-11-22)**: Initial POSIX stub support
  - GNU Hello builds successfully
  - Basic resource limit, signal, and directory stubs
  - Bash compatibility patches
  - Binutils partially building (pending coreutils fixes)
