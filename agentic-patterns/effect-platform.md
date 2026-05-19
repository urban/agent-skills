# Effect `Platform` patterns for agents

These notes capture how agents should write code against Effect's platform abstractions in this project. They are based on `repos/effect/packages/effect/src/FileSystem.ts`, `Path.ts`, `PlatformError.ts`, `unstable/http/HttpPlatform.ts`, the `@effect/platform-node` / `@effect/platform-bun` implementations and tests, and usage in `repos/t3code`, `repos/executor`, and `repos/alchemy-effect`.

## What `Platform` means here

`Platform` code is code that crosses an operating-system or runtime boundary: files, paths, stdio, terminals, child processes, sockets, HTTP servers, workers, and runtime entrypoints.

Use Effect platform services instead of direct runtime APIs:

- `FileSystem.FileSystem` instead of `node:fs` / `Bun.file` in application behavior.
- `Path.Path` instead of `node:path` / `pathe` in application behavior.
- `ChildProcessSpawner.ChildProcessSpawner` and `ChildProcess.make` instead of `child_process.spawn`.
- `HttpClient.HttpClient` / `HttpClientResponse.HttpClientResponse` at HTTP boundaries instead of `fetch` / web `Response`.
- `NodeServices.layer` / `BunServices.layer` only at runtime or test composition edges.

The Effect sources model these capabilities as services with typed errors. For example, `FileSystem` methods return `Effect<_, PlatformError>`, `Path.fromFileUrl` returns `Effect<string, BadArgument>`, and `HttpPlatform.fileResponse` returns `Effect<HttpServerResponse, PlatformError>`.

## First principles

- Encapsulate platform behavior behind domain services. Callers should ask for `WorkspaceFileSystem.writeFile`, `Profile.setProfile`, or `GitVcsDriver.execute`, not receive `FileSystem` and `Path` plumbing.
- Yield platform services from context inside an effect body: `const fs = yield* FileSystem.FileSystem`. Do not pass `fs`, `path`, or process spawners as normal arguments.
- Keep runtime-specific layers at the application edge. Domain services should depend on Effect service tags, not on `@effect/platform-node` or `@effect/platform-bun` modules.
- Prefer `Effect.fnUntraced` for platform methods unless a span is intentionally required. Use `Effect.fn` only when tracing is desired.
- Use `Stream.Stream` and `Sink.Sink` for streaming platform data. Do not write ad hoc reader loops in application implementations when `Stream` can model the flow.
- Use scoped resource APIs for temporary files, file handles, subprocesses, servers, and background work. Prefer `makeTempDirectoryScoped`, `makeTempFileScoped`, `Effect.scoped`, and `Effect.acquireRelease`.
- Keep final live layer compositions typed as `Layer.Layer<ProvidedServices>`. Let local and test layers infer naturally.

## Behavior encapsulation

Platform services are low-level capabilities. Application modules should translate them into domain behavior and domain errors.

Adapted from `repos/t3code/apps/server/src/workspace/Layers/WorkspaceFileSystem.ts`:

```ts
import { Context, Effect, FileSystem, Layer, Path, Schema } from "effect";

export class WorkspaceFileSystemError extends Schema.TaggedErrorClass<WorkspaceFileSystemError>()(
  "WorkspaceFileSystemError",
  {
    operation: Schema.String,
    relativePath: Schema.String,
    detail: Schema.String,
    cause: Schema.optional(Schema.Defect),
  },
) {}

export interface WorkspaceFileSystemShape {
  readonly writeFile: (input: {
    readonly cwd: string;
    readonly relativePath: string;
    readonly contents: string;
  }) => Effect.Effect<{ readonly relativePath: string }, WorkspaceFileSystemError>;
}

export class WorkspaceFileSystem extends Context.Service<
  WorkspaceFileSystem,
  WorkspaceFileSystemShape
>()("app/workspace/WorkspaceFileSystem") {}

export const makeWorkspaceFileSystem = Effect.fnUntraced(function* () {
  const fs = yield* FileSystem.FileSystem;
  const path = yield* Path.Path;

  const writeFile: WorkspaceFileSystemShape["writeFile"] = Effect.fnUntraced(function* (input) {
    const absolutePath = path.resolve(input.cwd, input.relativePath);

    yield* fs.makeDirectory(path.dirname(absolutePath), { recursive: true }).pipe(
      Effect.mapError(
        (cause) =>
          new WorkspaceFileSystemError({
            operation: "WorkspaceFileSystem.makeDirectory",
            relativePath: input.relativePath,
            detail: cause.message,
            cause,
          }),
      ),
    );

    yield* fs.writeFileString(absolutePath, input.contents).pipe(
      Effect.mapError(
        (cause) =>
          new WorkspaceFileSystemError({
            operation: "WorkspaceFileSystem.writeFile",
            relativePath: input.relativePath,
            detail: cause.message,
            cause,
          }),
      ),
    );

    return { relativePath: input.relativePath };
  });

  return WorkspaceFileSystem.of({ writeFile });
});

export const WorkspaceFileSystemLive: Layer.Layer<
  WorkspaceFileSystem,
  never,
  FileSystem.FileSystem | Path.Path
> = Layer.effect(WorkspaceFileSystem, makeWorkspaceFileSystem());
```

Why this shape matters:

- The implementation captures `FileSystem` and `Path` once at layer construction.
- The public API exposes workspace behavior, not raw file primitives.
- `PlatformError` is translated to a domain-specific tagged error at the boundary.
- Tests can replace only the platform layer or only the domain service layer.

## Modular, testable, maintainable services

### Capture platform requirements when the service owns the behavior

`repos/alchemy-effect/packages/alchemy/src/Auth/Profile.ts` documents this pattern: build a service layer that captures `FileSystem` at layer-build time, so the service methods themselves have `R = never`.

Use this when platform access is an implementation detail of the service:

```ts
import { Context, Effect, FileSystem, Layer, PlatformError, Schema } from "effect";

export const CONFIG_VERSION = 1;

export const ConfigSchema = Schema.Struct({
  version: Schema.Literal(CONFIG_VERSION),
  profiles: Schema.Record(Schema.String, Schema.Struct({ method: Schema.String })),
});

export type Config = typeof ConfigSchema.Type;

export interface ProfileShape {
  readonly readConfig: Effect.Effect<Config>;
  readonly writeConfig: (
    config: Config,
  ) => Effect.Effect<void, PlatformError.PlatformError | Schema.SchemaError>;
}

export class Profile extends Context.Service<Profile, ProfileShape>()("app/auth/Profile") {}

const emptyConfig = (): Config => ({ version: CONFIG_VERSION, profiles: {} });

export const ProfileLive: Layer.Layer<Profile, never, FileSystem.FileSystem> = Layer.effect(
  Profile,
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem;
    const configPath = ".app/profiles.json";
    const ConfigJson = Schema.fromJsonString(ConfigSchema);
    const decodeConfig = Schema.decodeEffect(ConfigJson);
    const encodeConfig = Schema.encodeEffect(ConfigJson);

    const readConfig = fs
      .readFileString(configPath)
      .pipe(Effect.flatMap(decodeConfig), Effect.orElseSucceed(emptyConfig));

    const writeConfig: ProfileShape["writeConfig"] = Effect.fnUntraced(function* (config) {
      const encoded = yield* encodeConfig(config);
      yield* fs.writeFileString(configPath, encoded);
    });

    return Profile.of({ readConfig, writeConfig });
  }),
);
```

### Leave requirements explicit for reusable platform helpers

`repos/alchemy-effect/packages/alchemy/src/Build/Memo.ts` uses a helper that still requires `FileSystem | Path`. This is useful for reusable functions that intentionally remain platform-polymorphic:

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

`repos/effect/packages/platform-node/src/NodeServices.ts` and `repos/effect/packages/platform-bun/src/BunServices.ts` merge focused layers into one runtime platform layer. `repos/t3code/apps/server/src/server.ts` and `repos/alchemy-effect/packages/alchemy/src/Util/PlatformServices.ts` choose Node or Bun at the outer runtime boundary.

Adapted pattern:

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

`repos/effect/packages/effect/src/PlatformError.ts` defines:

- `PlatformError`, a tagged error with `_tag: "PlatformError"`.
- `BadArgument`, for invalid arguments passed to a platform API.
- `SystemError`, with reason tags such as `NotFound`, `PermissionDenied`, `AlreadyExists`, `Busy`, `TimedOut`, `UnexpectedEof`, and `Unknown`.

Effect's Node file-system adapter maps Node errno values into `PlatformError.systemError` in `repos/effect/packages/platform-node-shared/src/internal/utils.ts`.

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

Adapted from `repos/effect/packages/effect/src/unstable/http/HttpStaticServer.ts`:

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

Adapted from Effect's Node file-system implementation and `repos/executor/tests/daemon-state.test.ts`:

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

`repos/effect/packages/effect/test/ConfigProvider.test.ts` and `repos/executor/tests/daemon-state.test.ts` override only the filesystem methods the test needs.

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

### Prefer scoped temp resources over manual cleanup

Adapted from `repos/effect/packages/platform-node-shared/test/NodeFileSystem.test.ts` and `repos/t3code/oxlint-plugin-t3code/test/utils.ts`:

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

Adapted from `repos/effect/packages/effect/test/unstable/process/ChildProcess.test.ts`:

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
