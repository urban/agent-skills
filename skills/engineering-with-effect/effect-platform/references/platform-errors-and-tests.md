# Platform errors and tests

Preserve typed reasons such as not-found, permission-denied, already-exists, busy, timed-out, invalid argument, and unexpected EOF until a domain boundary can translate them.

Recover narrowly. A missing optional file may map to an empty initial state; malformed contents, denied access, and storage outage must not take the same fallback.

## Test seams

- fake filesystem/path/process capability for focused domain behavior
- scoped real temp resources for filesystem integration
- scripted process handles for output, stderr, exit, timeout, and interruption
- real runtime adapter only for explicitly named platform integration tests

A fake should preserve relevant streaming, exit, error, and cleanup semantics rather than return only the happy-path aggregate.
