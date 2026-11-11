## apache-orc: fix buffer count type on 32-bit

### Description of changes

Use uint64_t rather than size_t when computing the number of floating-point
values available in a buffer. `numValues` is uint64_t, while the old expression
has a different type on 32-bit after division by bytesPerValue_. This breaks
std::min template deduction. The buffer count remains nonnegative and uses the
same type as numValues before the minimum is taken.

### Validation

- Baseline i686 fails compiling ColumnReader.cc with no matching std::min.
- Patched i686-linux and x86_64-linux builds succeed.
- No test configuration changes; the normal package does not run a check phase.
- Xfce ISO builds; live and installed desktop boot verified with the integration stack.

```sh
nix-build . -A apache-orc --argstr system i686-linux --option extra-platforms i686-linux
nix-build . -A apache-orc --argstr system x86_64-linux
```

Prepared with AI assistance; operator review required before submission.
