# Effect `Platform` patterns for agents — part 2

Covers:

- Leave requirements explicit for reusable platform helpers
- Compose platform adapters at the edge
- Error handling patterns
- Know the platform error shape
- Translate platform errors to domain errors at boundaries
- Build platform adapters with typed constructors
- Testing patterns
- Use FileSystem.layerNoop for focused behavior tests

---

### Leave requirements explicit for reusable platform helpers

A helper can still require `FileSystem | Path`. This is useful for reusable functions that intentionally remain platform-polymorphic:

```ts
import { Effect, FileSystem, Path, PlatformError } from "effect";

const Memo = Effect.gen(function* () {
  const fs = yield* FileSystem.FileSystem;
  const path = yield* Path.Path;

  const readGitIgnoreRules = Effect.fnUntraced(function* (
    cwd: string,
  ): Effect.fn.Return<ReadonlyArray<string>, PlatformError.PlatformError> {
    const rules = yield* fs.readFileString(path.join(cwd, ".gitignore")).pipe(
      Effect.map((file) => file.split("\n")),
      Effect.catchIf(
        (error) => error.reason._tag === "NotFound",
        () => Effect.succeed([]),
      ),
    );

    return rules;
  });

  return { readGitIgnoreRules };
});

export const loadIgnoreRules = Effect.fnUntraced(function* (cwd: string) {
  const memo = yield* Memo;
  return yield* memo.readGitIgnoreRules(cwd);
});
```

Guideline: choose one of these two shapes intentionally. Do not accidentally leak `FileSystem | Path` requirements from high-level services.

### Compose platform adapters at the edge

`.dotai/repos/effect/packages/platform-node/src/NodeServices.ts` and `.dotai/repos/effect/packages/platform-bun/src/BunServices.ts` merge focused layers into one runtime platform layer. Choose Node or Bun at the outer runtime boundary.

```ts
import { Effect, Layer } from "effect";
import type { FileSystem } from "effect/FileSystem";
import type { Path } from "effect/Path";
import type { Stdio } from "effect/Stdio";
import type { Terminal } from "effect/Terminal";
import type { ChildProcessSpawner } from "effect/unstable/process/ChildProcessSpawner";

export type PlatformServices = ChildProcessSpawner | FileSystem | Path | Stdio | Terminal;

export const PlatformServicesLive: Layer.Layer<PlatformServices> = Effect.promise(async () => {
  if (typeof Bun !== "undefined") {
    const BunServices = await import("@effect/platform-bun/BunServices");
    return BunServices.layer;
  }

  const NodeServices = await import("@effect/platform-node/NodeServices");
  return NodeServices.layer;
}).pipe(Layer.unwrap);
```

Keep this kind of dynamic import out of domain services. Runtime selection belongs in `server.ts`, CLI entrypoints, or an infrastructure module.

## Error handling patterns

### Know the platform error shape

`.dotai/repos/effect/packages/effect/src/PlatformError.ts` defines:

- `PlatformError`, a tagged error with `_tag: "PlatformError"`.
- `BadArgument`, for invalid arguments passed to a platform API.
- `SystemError`, with reason tags such as `NotFound`, `PermissionDenied`, `AlreadyExists`, `Busy`, `TimedOut`, `UnexpectedEof`, and `Unknown`.

Effect's Node file-system adapter maps Node errno values into `PlatformError.systemError` in `.dotai/repos/effect/packages/platform-node-shared/src/internal/utils.ts`.

Use typed matching on the error channel:

```ts
const readOptionalText = (path: string) =>
  fs.readFileString(path).pipe(
    Effect.catchIf(
      (error) => error.reason._tag === "NotFound",
      () => Effect.succeed(undefined),
    ),
  );
```

Do not probe arbitrary unknown values with `"_tag" in error`. If the effect says it fails with `PlatformError.PlatformError`, match that typed error directly.

### Translate platform errors to domain errors at boundaries

```ts
import { Effect, PlatformError, Schema } from "effect";

export class StaticFileError extends Schema.TaggedErrorClass<StaticFileError>()("StaticFileError", {
  reason: Schema.Literals(["NotFound", "Unavailable"]),
  path: Schema.String,
  cause: Schema.optional(Schema.Defect),
}) {}

const handlePlatformError = <A>(
  path: string,
  effect: Effect.Effect<A, PlatformError.PlatformError>,
) =>
  effect.pipe(
    Effect.catchIf(
      (error) => error.reason._tag === "NotFound",
      (cause) => Effect.fail(new StaticFileError({ reason: "NotFound", path, cause })),
    ),
    Effect.catchTag("PlatformError", (cause) =>
      Effect.fail(new StaticFileError({ reason: "Unavailable", path, cause })),
    ),
  );
```

Use this pattern when callers can take different actions for different domain outcomes. If a failure is not actionable, do not expose it as a typed service error; let it remain a defect or map it at the top-level boundary.

### Build platform adapters with typed constructors

```ts
import { Effect, PlatformError } from "effect";
import * as FsPromises from "node:fs/promises";

const toFileSystemError = (method: string, path: string, cause: unknown) =>
  PlatformError.systemError({
    _tag: "Unknown",
    module: "FileSystem",
    method,
    pathOrDescriptor: path,
    cause,
  });

const writeFile = (path: string, data: Uint8Array) =>
  Effect.tryPromise({
    try: () => FsPromises.writeFile(path, data),
    catch: (cause) => toFileSystemError("writeFile", path, cause),
  });
```

Prefer existing platform services over writing adapters yourself. Only write adapters at true platform boundaries.

## Testing patterns

### Use `FileSystem.layerNoop` for focused behavior tests

`.dotai/repos/effect/packages/effect/test/ConfigProvider.test.ts` overrides only the filesystem methods the test needs.

```ts
import { Effect, FileSystem, PlatformError } from "effect";

const TestFileSystem = FileSystem.layerNoop({
  readFileString(path) {
    if (path === ".env") {
      return Effect.succeed("A=1\n");
    }

    return Effect.fail(
      PlatformError.systemError({
        _tag: "NotFound",
        module: "FileSystem",
        method: "readFileString",
        pathOrDescriptor: path,
      }),
    );
  },
  exists: () => Effect.succeed(false),
});

const testProgram = program.pipe(Effect.provide(TestFileSystem));
```

Use `layerNoop` when the unit under test only needs a few file operations. Use `NodeServices.layer` or `BunServices.layer` for integration tests that intentionally hit the real platform.
