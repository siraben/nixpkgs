# Feather-tk public FileIO seam — parent source audit

Exact fetched source: `/nix/store/1bylhb9g2aphmj3a1gha4kld9zkbcqfc-source`,
selected by the pinned Nix package (`feather-tk-pinned-source-fetch.json`).

- `lib/feather-tk/core/FileIO.h:43–49`: `InMemoryFile` consists of a
  `const uint8_t*` and `size_t`. Neither changes width with `_FILE_OFFSET_BITS`.
- `FileIO.h:98–145`: size, position, seek/read/write interfaces use `size_t`
  and explicitly sized integer types, not libc `off_t` or directory records.
- `FileIO.h:185–188`: implementation state is behind `FEATHER_TK_PRIVATE()`.
- `core/Util.h:16–18`: that macro declares `struct Private` and
  `std::unique_ptr<Private> _p`; it does not inline a libc layout into FileIO.
- A bounded scan of FileIO.h, FileIOInline.h, String.h and Util.h found no
  public `off_t`, `ino_t`, `struct stat`, `struct dirent`, `fpos_t` or `FILE*`
  occurrence. This closes the specifically identified FileIO/InMemoryFile
  width seam; it is not an exhaustive audit of every external dependency.

No new repair indicated for this seam. Actual tlRender/DJV runtime closure
coverage is still not claimed. The recorded i686 package metadata says all
listed consumers are available/not broken, but that does not establish that
all their dependency graphs build or run on i686.
