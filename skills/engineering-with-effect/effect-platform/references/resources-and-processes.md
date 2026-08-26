# Resources and processes

## Scoped ownership

Acquire temporary paths, file handles, subprocesses, servers, sockets, and subscriptions in a scope with their release action. Verify cleanup after success, failure, and interruption.

## Processes

- Stream stdout and stderr concurrently to avoid pipe deadlock.
- Bound collection when output can be large.
- Decide whether non-zero exit is an expected typed outcome or a defect in the invoking boundary.
- Separate spawn failure, timeout, signal/interruption, output-limit, and exit-code semantics when callers react differently.
- Keep raw process handles private unless callers own kill, stdin, or lifetime control.

## Temporary resources

Scoped temporary directories and files prevent leaks after test failures. Do not return a path from a closed scope unless the resource is intentionally transferred to a longer-lived owner.
