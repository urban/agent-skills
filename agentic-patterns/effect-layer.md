# Effect `Layer` patterns for agents

## First principles

- A `Layer<ROut, E, RIn>` is a recipe for building services: it **provides** `ROut`, can fail with `E`, and **requires** `RIn`.
- Use layers as composition boundaries, not as business logic modules. Domain behavior belongs behind `Context.Service` contracts; layers wire concrete implementations and lifetimes.
- Prefer one focused layer per service implementation. Compose those layers into application layers at the edge.
- Capture dependencies from context inside `Layer.effect` / service `make` effects with `yield* Service`. Do not pass service instances as ordinary function arguments.
- Use `Layer.succeed` for pure, already-created implementations and fakes.
- Use `Layer.effect` for implementations that need Effect services, configuration, validation, references, or scoped resource acquisition.
- Use `Layer.effectDiscard` only when a layer intentionally provides no services, such as background tasks or startup instrumentation.
- Use `Layer.unwrap` when configuration or runtime state chooses which layer to build.
- Treat layer sharing as intentional. Layers are memoized by the current `MemoMap`; the same layer value is built once and shared until its observers close.
- Final live layers should be typed as `Layer.Layer<ProvidedServices>`. Let intermediate and local test layers infer naturally.

## Encapsulate behavior behind services, not layers

A layer should reveal a capability and hide how that capability is built. The service owns the public methods, typed errors, data normalization, and dependency usage. The layer owns construction.

```ts
import { Context, Effect, Layer, Option, Schema } from "effect";

export interface User {
  readonly id: string;
  readonly name: string;
}

export class UserRepositoryError extends Schema.TaggedErrorClass<UserRepositoryError>()(
  "UserRepositoryError",
  {
    reason: Schema.Literals(["StorageUnavailable", "InvalidUserData"]),
    detail: Schema.String,
  },
) {}

export interface SqlClientShape {
  readonly findUser: (id: string) => Effect.Effect<Option.Option<User>, UserRepositoryError>;
}

export class SqlClient extends Context.Service<SqlClient, SqlClientShape>()("myapp/SqlClient") {}

export class UserRepository extends Context.Service<
  UserRepository,
  {
    readonly findById: (id: string) => Effect.Effect<Option.Option<User>, UserRepositoryError>;
  }
>()("myapp/UserRepository") {
  static readonly layerNoDeps: Layer.Layer<UserRepository, never, SqlClient> = Layer.effect(
    UserRepository,
    Effect.gen(function* () {
      const sql = yield* SqlClient;

      return UserRepository.of({
        findById: (id) => sql.findUser(id),
      });
    }),
  );

  static readonly layer: Layer.Layer<UserRepository> = this.layerNoDeps.pipe(
    Layer.provide(
      Layer.succeed(
        SqlClient,
        SqlClient.of({
          findUser: () => Effect.succeed(Option.none()),
        }),
      ),
    ),
  );
}
```

## Keep services modular, testable, and maintainable

### Split construction from composition

Use this shape for most service modules:

1. domain types and schemas,
2. tagged errors,
3. `Context.Service` class,
4. `make` effect or `layerNoDeps`,
5. live/test layers that compose dependencies.

For larger services, put dependency capture in a `make` effect and export a layer that provides the service. This keeps methods small and easy to test.

```ts
import { Context, Effect, Layer, Schema } from "effect";

export interface VcsProcessOutput {
  readonly stdout: string;
  readonly stderr: string;
}

export class VcsProcessError extends Schema.TaggedErrorClass<VcsProcessError>()("VcsProcessError", {
  detail: Schema.String,
}) {}

export class VcsProcess extends Context.Service<
  VcsProcess,
  {
    readonly run: (input: {
      readonly operation: string;
      readonly command: string;
      readonly args: ReadonlyArray<string>;
      readonly cwd: string;
      readonly timeoutMs: number;
    }) => Effect.Effect<VcsProcessOutput, VcsProcessError>;
  }
>()("myapp/VcsProcess") {}

export class GitHostCliError extends Schema.TaggedErrorClass<GitHostCliError>()("GitHostCliError", {
  operation: Schema.String,
  detail: Schema.String,
}) {}

export class GitHostCli extends Context.Service<
  GitHostCli,
  {
    readonly createPullRequest: (input: {
      readonly cwd: string;
      readonly baseBranch: string;
      readonly headSelector: string;
      readonly title: string;
      readonly bodyFile: string;
    }) => Effect.Effect<void, GitHostCliError>;
  }
>()("myapp/GitHostCli") {}

const mapCliError = (operation: string, error: VcsProcessError) =>
  new GitHostCliError({ operation, detail: error.detail });

export const makeGitHostCli = Effect.fnUntraced(function* () {
  const process = yield* VcsProcess;

  const execute = (input: { readonly cwd: string; readonly args: ReadonlyArray<string> }) =>
    process
      .run({
        operation: "GitHostCli.execute",
        command: "gh",
        args: input.args,
        cwd: input.cwd,
        timeoutMs: 30_000,
      })
      .pipe(Effect.mapError((error) => mapCliError("execute", error)));

  return GitHostCli.of({
    createPullRequest: (input) =>
      execute({
        cwd: input.cwd,
        args: [
          "pr",
          "create",
          "--base",
          input.baseBranch,
          "--head",
          input.headSelector,
          "--title",
          input.title,
          "--body-file",
          input.bodyFile,
        ],
      }).pipe(Effect.asVoid),
  });
});

export const GitHostCliLayer: Layer.Layer<GitHostCli, never, VcsProcess> = Layer.effect(
  GitHostCli,
  makeGitHostCli(),
);
```

Example pattern:

### Compose with the right operator

- `Layer.mergeAll(a, b, c)` builds independent layers concurrently and exposes all their services.
- `Layer.provide(deps)` supplies dependencies to a layer and hides those dependency services from the output.
- `Layer.provideMerge(deps)` supplies dependencies and keeps them in the output. Use this for tests or middleware stacks that still need direct access to lower-level services.

```ts
import { Layer } from "effect";

const DbLive = DbService.Live;
const UserStoreLive = UserStoreService.Live.pipe(Layer.provide(DbLive));

export const RequestScopedServicesLive = Layer.mergeAll(DbLive, UserStoreLive);

export const BootSharedServices = Layer.mergeAll(
  CoreSharedServices,
  HttpServer.layerServices,
  TelemetryLive,
);

export const NonProtectedApiLive = HttpApiBuilder.layer(NonProtectedApi).pipe(
  Layer.provide(Layer.mergeAll(CloudAuthPublicHandlers, CloudSessionAuthHandlers)),
  Layer.provideMerge(ApiKeyService.WorkOS),
  Layer.provide(requestScopedMiddleware(RequestScopedServicesLive).layer),
  Layer.provideMerge(SessionAuthLive),
);
```

Example pattern:

## Resource and lifetime patterns

### Use scoped acquisition in `Layer.effect`

If a service owns a socket, file handle, process, client, or subscription, acquire it inside the layer and register release with `Effect.acquireRelease`. Effect's layer tests verify that finalizers run when the scope closes, that `provide` releases nested resources in reverse dependency order, and that interruption releases anything already acquired.

```ts
import { Context, Effect, Layer } from "effect";

export interface DbServiceShape {
  readonly query: (sql: string) => Effect.Effect<ReadonlyArray<unknown>>;
}

interface DbResource extends DbServiceShape {
  readonly close: Effect.Effect<void>;
}

const makeDbResource = Effect.sync(
  (): DbResource => ({
    query: () => Effect.succeed([]),
    close: Effect.void,
  }),
);

export class DbService extends Context.Service<DbService, DbServiceShape>()("myapp/DbService") {
  static readonly Live: Layer.Layer<DbService> = Layer.effect(
    DbService,
    Effect.acquireRelease(makeDbResource, (resource) => resource.close),
  );
}
```

### Be explicit about shared vs per-request lifetimes

Default layer memoization is usually desirable. It is wrong for request-bound resources in runtimes that forbid cross-request I/O reuse. In that case, build the request-scoped layer inside request handling with a fresh `MemoMap` and the request scope.

```ts
import { Effect, Layer } from "effect";
import { HttpRouter } from "effect/unstable/http";

export const requestScopedMiddleware = <A>(layer: Layer.Layer<A>) =>
  HttpRouter.middleware<{ provides: A }>()((httpEffect) =>
    Effect.scoped(
      Effect.gen(function* () {
        const memoMap = yield* Layer.makeMemoMap;
        const scope = yield* Effect.scope;
        const services = yield* Layer.buildWithMemoMap(layer, memoMap, scope);
        return yield* Effect.provideContext(httpEffect, services);
      }),
    ),
  );
```

The important rule is not “always manual-build layers”; it is “manual-build only at a lifetime boundary that Effect's normal application composition cannot express.”

### Use `Layer.fresh` sparingly

`Layer.fresh(layer)` disables sharing for that layer value. The Effect tests show it causes a duplicated acquisition when the same layer is merged or provided more than once. Use it only when each consumer must have independent state or an independent resource.

## Dynamic and optional layers

Use `Layer.unwrap` when an Effect decides which layer should exist. Good uses include configuration, optional telemetry, and environment-specific implementations.

```ts
import { Effect, Layer } from "effect";

const buildTelemetryLayer = (attributes: Record<string, string>): Layer.Layer<never> =>
  Layer.mergeAll(TracerLayer(attributes), MetricsLayer(attributes), LoggerLayer(attributes)).pipe(
    Layer.provide(JsonSerializationLayer),
    Layer.provide(HttpClientLayer),
  );

export const TelemetryLive: Layer.Layer<never> = Layer.unwrap(
  Effect.gen(function* () {
    const disabled = yield* isTelemetryDisabled;
    if (disabled) {
      return Layer.empty;
    }

    const attributes = yield* collectTelemetryAttributes;
    return buildTelemetryLayer(attributes);
  }),
);
```

Example pattern:

## Error handling patterns

- Services should expose typed errors for actionable failures. Use `Schema.TaggedErrorClass` and narrow with `Effect.catchTag` / `Effect.catchTags` in callers.
- Map lower-level dependency errors at the service boundary, inside `make` or method implementations.
- Layer construction errors should remain typed unless they are truly unrecoverable at final composition.
- Use `Layer.catchTag` when a layer has a meaningful fallback implementation.
- Use `Layer.orDie` only on final live compositions whose remaining construction errors are defects from the application's point of view.
- Do not use `Effect.orDie`. If a typed failure is non-actionable at a service boundary, handle that specific tag and die deliberately.

```ts
import { Context, Effect, Layer, Schema } from "effect";

export class PrimaryUnavailable extends Schema.TaggedErrorClass<PrimaryUnavailable>()(
  "PrimaryUnavailable",
  { detail: Schema.String },
) {}

export class MessageStore extends Context.Service<
  MessageStore,
  {
    readonly append: (message: string) => Effect.Effect<void>;
    readonly all: Effect.Effect<ReadonlyArray<string>>;
  }
>()("myapp/MessageStore") {}

const inMemoryStore = Layer.effect(
  MessageStore,
  Effect.sync(() => {
    const messages: Array<string> = [];
    return MessageStore.of({
      append: (message) =>
        Effect.sync(() => {
          messages.push(message);
        }),
      all: Effect.sync(() => [...messages]),
    });
  }),
);

const remoteStore = Layer.effect(
  MessageStore,
  Effect.gen(function* () {
    return yield* new PrimaryUnavailable({ detail: "remote store is unavailable" });
  }),
);

export const MessageStoreLive: Layer.Layer<MessageStore> = remoteStore.pipe(
  Layer.catchTag("PrimaryUnavailable", () => inMemoryStore),
);
```

## Test-layer patterns

- Prefer production composition in tests. Replace true external boundaries with `Layer.succeed` or `Layer.mock`.
- Use `Layer.provideMerge` in test layers when assertions need access to lower-level test state.
- Keep test state in services such as `Ref.Ref<ReadonlyArray<T>>` rather than module globals when the state belongs to the layer.
- Use a shared test layer only when shared state across tests is intentional. Otherwise, build/provide a fresh layer per test.

```ts
import { assert, it, vi } from "@effect/vitest";
import { Context, Effect, Layer, Ref } from "effect";

interface Todo {
  readonly id: number;
  readonly title: string;
}

export class TodoRepoTestRef extends Context.Service<
  TodoRepoTestRef,
  Ref.Ref<ReadonlyArray<Todo>>
>()("myapp/TodoRepoTestRef") {
  static readonly layer = Layer.effect(TodoRepoTestRef, Ref.make<ReadonlyArray<Todo>>([]));
}

export class TodoRepo extends Context.Service<
  TodoRepo,
  {
    readonly create: (title: string) => Effect.Effect<Todo>;
    readonly list: Effect.Effect<ReadonlyArray<Todo>>;
  }
>()("myapp/TodoRepo") {
  static readonly layerTest = Layer.effect(
    TodoRepo,
    Effect.gen(function* () {
      const store = yield* TodoRepoTestRef;

      return TodoRepo.of({
        create: (title) =>
          Ref.modify(store, (todos) => {
            const todo = { id: todos.length + 1, title };
            return [todo, [...todos, todo]];
          }),
        list: Ref.get(store),
      });
    }),
  ).pipe(Layer.provideMerge(TodoRepoTestRef.layer));
}

const mockRun = vi.fn<(command: string) => Effect.Effect<string>>();

const ExternalBoundaryTest = Layer.mock(ExternalBoundary)({
  run: mockRun,
});

it.effect("uses the test repository", () =>
  Effect.gen(function* () {
    const repo = yield* TodoRepo;
    yield* repo.create("Write docs");
    assert.deepStrictEqual(yield* repo.list, [{ id: 1, title: "Write docs" }]);
  }).pipe(Effect.provide(TodoRepo.layerTest)),
);
```

## Background and entrypoint layers

Use `Layer.effectDiscard` for scoped background work that does not provide a service. Fork long-running work with `Effect.forkScoped` so it is interrupted when the layer scope closes.

```ts
import { Effect, Layer } from "effect";

export const BackgroundSync = Layer.effectDiscard(
  Effect.gen(function* () {
    yield* Effect.gen(function* () {
      while (true) {
        yield* Effect.sleep("5 seconds");
        yield* runSyncOnce;
      }
    }).pipe(Effect.forkScoped);
  }),
);
```

Use `Layer.launch` only at process/application entrypoints where the application is represented as a long-running layer, such as an HTTP server or worker.

## What to avoid

- Do not put domain branching, parsing, or orchestration directly in a top-level application layer. Put it in services and provide those services with layers.
- Do not build layers manually inside ordinary service methods. Manual `Layer.build`, `Layer.buildWithScope`, or `Layer.buildWithMemoMap` belongs at runtime lifetime boundaries.
- Do not rely on default sharing for request-bound resources, sockets, streams, or Worker I/O objects that must be scoped to one request.
- Do not use `Layer.provideMerge` by default. If callers should not see dependency services, use `Layer.provide`.
- Do not use `Layer.orDie` to hide recoverable configuration, validation, network, SQL, or auth failures.
- Do not expose `unknown` error channels from layers. Keep layer and service errors precise.
- Do not create generic errors like `ServiceFailed` or `UnknownError`; define specific tagged errors with actionable fields.
- Do not use partial mocks as a substitute for behavior tests. `Layer.mock` is for replacing external boundaries or services irrelevant to the assertion.
- Do not use module-level mutable state for test doubles when the state should be tied to layer lifetime. Use `Ref`, `Layer.effect`, and scoped test layers.
- Do not add spans around every layer by habit. Use `Layer.withSpan` only when layer construction or lifetime needs explicit observability; method-level spans should use `Effect.fn` when required by the project rules.
