# Platform errors and tests

## Translate reasons, not messages

Filesystem operations commonly fail with an outer `PlatformError` whose `reason` is either `BadArgument` or a normalized system reason such as `NotFound` or `PermissionDenied`. Keep its operation details, path/descriptor, and original cause until the domain boundary decides what they mean. Do not parse error messages or cast host errno values into domain failures.

Reason normalization is adapter-specific and can yield `Unknown`; the existence of a normalized tag does not guarantee every host failure maps to it. Nor does every capability use this wrapper: path URL conversion can fail directly with `BadArgument`, terminal input has `QuitError`, and sockets use `SocketError`. Translate the errors of the operation being adapted rather than forcing all host failures into one shape.

A missing optional file can mean an empty initial state, but denied access or malformed contents cannot. Recover at the read operation, before parsing, so a parsing failure cannot accidentally select the absence fallback:

```ts
import { Effect, FileSystem, Option } from "effect"

const readOptionalText = (path: string) => Effect.gen(function*() {
  const fs = yield* FileSystem.FileSystem
  return yield* fs.readFileString(path).pipe(
    Effect.map(Option.some),
    Effect.catchTag("PlatformError", (error) =>
      error.reason._tag === "NotFound"
        ? Effect.succeed(Option.none<string>())
        : Effect.fail(error))
  )
})
```

`FileSystem.exists` likewise returns false only for not-found; permission failures remain failures. An existence check before a read or create is not a reservation: handle failure on the actual operation to avoid check/use races.

## Test seams

- Test domain decisions with a fake domain capability. Use a fake filesystem or process spawner when exercising the infrastructure adapter's translation and command policy.
- `FileSystem.layerNoop` / `makeNoop` are partial stubs, not in-memory filesystems: `exists` defaults to false, `remove` succeeds, and unspecified methods can fail or die. Overrides are independent; overriding `readFile` does not derive `readFileString`. Override the operations under test and record relevant calls rather than mistaking default no-ops for verified behavior.
- Assert that an optional-file boundary recovers from `NotFound` but propagates `PermissionDenied`; test invalid contents separately after a successful read. Retain causes when asserting a translated domain error.
- Use scoped real temp resources for file behavior involving path resolution, symlinks, permissions, or cleanup. Assert resource removal after the owning scope closes on success, failure, and interruption, not just that a finalizer callback was registered.
- Script fake process output, stderr, status, and release independently. A fake whose pipes never backpressure cannot establish freedom from pipe deadlock; a fake with immediate exit cannot establish cancellation behavior.
- Use live runtime tests for large simultaneous stdout/stderr, failed stdin, a non-zero exit versus spawn failure, and cancellation of a child that ignores SIGTERM. Assert the required descendant cleanup on each supported OS. Real child processes and OS signals need live-time tests; advancing an Effect test clock does not advance the child or Node's force-kill timer.
