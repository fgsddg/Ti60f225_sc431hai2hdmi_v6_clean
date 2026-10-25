#include <errno.h>
#include <stddef.h>
#include <sys/reent.h>
#include <sys/stat.h>
#include <sys/types.h>

int _close_r(struct _reent *ptr, int fd)
{
    (void)ptr;
    (void)fd;
    return -1;
}

_off_t _lseek_r(struct _reent *ptr, int fd, _off_t offset, int whence)
{
    (void)ptr;
    (void)fd;
    (void)offset;
    (void)whence;
    return (_off_t)0;
}

_ssize_t _read_r(struct _reent *ptr, int fd, void *buf, size_t count)
{
    (void)ptr;
    (void)fd;
    (void)buf;
    (void)count;
    return (_ssize_t)0;
}

_ssize_t _write_r(struct _reent *ptr, int fd, const void *buf, size_t count)
{
    (void)ptr;
    (void)fd;
    (void)buf;
    return (_ssize_t)count;
}

int _fstat_r(struct _reent *ptr, int fd, struct stat *st)
{
    (void)ptr;
    (void)fd;
    if (st) {
        st->st_mode = S_IFCHR;
    }
    return 0;
}

int _isatty_r(struct _reent *ptr, int fd)
{
    (void)ptr;
    (void)fd;
    return 1;
}

int _open_r(struct _reent *ptr, const char *path, int flags, int mode)
{
    (void)ptr;
    (void)path;
    (void)flags;
    (void)mode;
    errno = ENOSYS;
    return -1;
}
