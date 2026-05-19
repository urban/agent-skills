# Effect `Platform` patterns for agents — part 1

Covers:

- Effect Platform patterns for agents
- What Platform means here
- First principles
- Behavior encapsulation
- Modular, testable, maintainable services
- Capture platform requirements when the service owns the behavior

---

# Effect `Platform` patterns for agents

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

Example pattern:

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

Build a service layer that captures `FileSystem` at layer-build time, so the service methods themselves have `R = never`.

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
