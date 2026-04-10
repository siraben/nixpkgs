/* Stub fadvise.h for cosmopolitan libc compatibility.
 *
 * Cosmopolitan declares fadvise(int, ...) with an incompatible signature
 * and POSIX_FADV_* as non-constant expressions.  This replaces gnulib's
 * fadvise.h with no-op stubs and renames the FILE*-based wrapper to
 * gl_fadvise to avoid the symbol conflict.
 */
#ifndef _GL_FADVISE_H
#define _GL_FADVISE_H
#include <stdio.h>

typedef int fadvice_t;

enum {
  FADVISE_NORMAL     = 0,
  FADVISE_SEQUENTIAL = 0,
  FADVISE_NOREUSE    = 0,
  FADVISE_DONTNEED   = 0,
  FADVISE_WILLNEED   = 0,
  FADVISE_RANDOM     = 0,
};

static inline void fdadvise(int fd, off_t offset, off_t len, fadvice_t advice)
{
  (void)fd; (void)offset; (void)len; (void)advice;
}

/* Rename to avoid conflict with cosmopolitan's fadvise(int, ...) */
#define fadvise gl_fadvise
static inline void gl_fadvise(FILE *fp, fadvice_t advice)
{
  (void)fp; (void)advice;
}

#endif /* _GL_FADVISE_H */
