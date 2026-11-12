## gavl: use 64-bit glibc time on 32-bit platforms

Select glibc's 64-bit time and large-file ABIs on 32-bit GNU platforms.
The HTTP timestamp API uses int64_t and passes that pointer to gmtime_r;
with native 32-bit time_t this is incompatible and GCC rejects the build.
Enabling the matching time ABI avoids both the pointer mismatch and truncating
post-2038 timestamps. Other architectures/libcs retain their existing flags.

The package already enables _FILE_OFFSET_BITS=64 for its internal library
build. Include both required macros in the compiler environment so the glibc
feature requirement is satisfied consistently. This follows the existing
tayga package pattern, with a narrower glibc platform guard.

### Validation

- Full package builds pass on i686 and x86_64.
- A consumer compiled against the public headers with its default libc ABI
  formats/parses HTTP timestamps for epoch zero, -1 second and January 1, 2040
  successfully on both architectures.
- Public headers contain no actual time_t/stat/timespec/timeval types in the
  exposed API; the timestamp API remains int64_t. One metatag comment mentions
  time_t, but is not a public libc struct/type declaration.
- No full multimedia playback or ARM validation claimed.

```sh
nix-build . -A gavl --argstr system i686-linux --option extra-platforms i686-linux
nix-build . -A gavl --argstr system x86_64-linux
```

Additional regression evidence: `gavl-{i686,x86_64}-http-time.log` and
`gavl-http-time-test.{c,nix}` in the refresh work directory.
This focused branch is on a238bac4849a79e151329cdc51638d3bc7627c6c; builds
were validated in the integration stack, not every other fix reverted.

Prepared with AI assistance; operator review required before submission.
