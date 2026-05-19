# Effect `Platform` patterns for agents — part 3

Covers:

- Prefer scoped temp resources over manual cleanup
- Mock child processes with services, streams, and sinks
- What to avoid

---

### Prefer scoped temp resources over manual cleanup

```ts
import { Effect, FileSystem, Path } from "effect";

const withFixture = Effect.scoped(
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem;
    const path = yield* Path.Path;
    const fixtureDir = yield* fs.makeTempDirectoryScoped({ prefix: "fixture-" });
    const sourcePath = path.join(fixtureDir, "source.ts");

    yield* fs.writeFileString(sourcePath, "export const value = 1;\n");

    return sourcePath;
  }),
);
```

Scoped temp resources make tests deterministic and avoid cleanup bugs.

### Mock child processes with services, streams, and sinks

```ts
import { Effect, Layer, Sink, Stream } from "effect";
import { ChildProcessSpawner } from "effect/unstable/process";

const MockChildProcessSpawner = Layer.succeed(
  ChildProcessSpawner.ChildProcessSpawner,
  ChildProcessSpawner.make(
    Effect.fnUntraced(function* (command) {
      const output = new TextEncoder().encode(`mock output for ${command._tag}`);

      return ChildProcessSpawner.makeHandle({
        pid: ChildProcessSpawner.ProcessId(12345),
        stdin: Sink.drain,
        stdout: Stream.fromIterable([output]),
        stderr: Stream.empty,
        all: Stream.fromIterable([output]),
        exitCode: Effect.succeed(ChildProcessSpawner.ExitCode(0)),
        isRunning: Effect.succeed(false),
        kill: () => Effect.void,
        getInputFd: () => Sink.drain,
        getOutputFd: () => Stream.empty,
        unref: Effect.succeed(Effect.void),
      });
    }),
  ),
);
```

This keeps process behavior deterministic and lets callers exercise stream collection, exit-code handling, and error mapping without shelling out.

## What to avoid

- Do not import `node:fs`, `node:path`, `node:child_process`, or Bun-specific APIs inside domain services. Use Effect platform services.
- Do not pass `FileSystem`, `Path`, or child-process service instances as function parameters. Yield services from context.
- Do not let high-level domain APIs expose platform primitives unless platform access is the purpose of the API.
- Do not map every platform failure to a generic `XFailed`, `InternalError`, or `UnknownError`. Use specific tagged errors with actionable reasons.
- Do not erase error channels with `unknown`; preserve `PlatformError.PlatformError` or map to a precise domain error.
- Do not use `Effect.orDie` in this project. If Effect source examples use it for release finalizers, adapt the code to handle typed errors explicitly or defect only at a final unrecoverable boundary.
- Do not use type assertions, non-null assertions, `any`, direct `JSON.parse`, or direct `JSON.stringify` in application code. Use Effect Schema codecs at boundaries.
- Do not top-level import `@effect/platform-node` from code that can run under Bun or in the browser. Choose runtime adapters at the edge with `Layer.unwrap` or dynamic imports.
- Do not test platform behavior by sleeping, relying on wall-clock races, or leaving temp files behind. Use `Effect.scoped`, `TestClock` where applicable, and platform test layers.
- Do not hand-roll async generators, web readers, or stream loops when `Stream` and `Sink` model the platform interaction.
