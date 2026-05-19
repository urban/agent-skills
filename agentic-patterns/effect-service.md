# Effect `Context.Service` patterns for agents

## First principles

- Use `Context.Service` for new services. Do not use old v3 APIs such as `Context.Tag`, `Context.GenericTag`, `Effect.Tag`, or `Effect.Service`.
- Prefer class syntax for application services:
  `export class Thing extends Context.Service<Thing, ThingShape>()("pkg/path/Thing") {}`.
- Treat the service class as both the dependency key and an Effect. `const thing = yield* Thing` reads the implementation from the current fiber context.
- Treat the service shape as the public capability contract. Keep it small, domain-oriented, and stable.
- Use stable, package-scoped identifiers such as `"app/process/ProcessRunner"`, `"@app/plugin-openapi/OpenApiExtensionService"`, or `"app/State"`.
- Build implementations with `Thing.of({ ... })`. `of` just returns the implementation shape; resource acquisition, dependency capture, validation, and error mapping belong in `make`, `Layer.effect`, or private helpers.
- A `make` option on `Context.Service` stores a constructor effect, but it does not create a layer. Define `static readonly layer = Layer.effect(this, this.make)` or an exported `layer` yourself.
- In this project, use `Effect.fnUntraced` for effectful wrappers unless spans are required. Use `Effect.fn` only when the method should create spans.

```ts
import { Context, Effect, Layer, Schema } from "effect";

export class DatabaseError extends Schema.TaggedErrorClass<DatabaseError>()("DatabaseError", {
  reason: Schema.Literals(["Unavailable", "InvalidQuery"]),
  detail: Schema.String,
}) {}

export interface DatabaseShape {
  readonly query: (sql: string) => Effect.Effect<ReadonlyArray<unknown>, DatabaseError>;
}

export class Database extends Context.Service<Database, DatabaseShape>()("myapp/db/Database") {
  static readonly layer: Layer.Layer<Database> = Layer.effect(
    Database,
    Effect.sync(() =>
      Database.of({
        query: Effect.fnUntraced(function* (sql: string) {
          if (sql.trim() === "") {
            return yield* Effect.fail(
              new DatabaseError({
                reason: "InvalidQuery",
                detail: "query must not be empty",
              }),
            );
          }

          return [{ id: 1, name: "Alice" }];
        }),
      }),
    ),
  );
}

export type DatabaseService = Database["Service"];
```

## Encapsulate behavior behind capabilities

A service should own one coherent behavior boundary.

- Wrap external systems such as SQL, HTTP, files, processes, desktop APIs, cloud resources, queues, and plugin SDKs.
- Expose domain operations, not implementation tools. For example, expose `createPullRequest`, not raw `child_process.spawn` details.
- Decode and normalize external data inside the service. Callers should receive domain values and typed domain errors.
- Map dependency errors at the service boundary. Do not leak raw process, HTTP, SQL, or vendor errors unless that is the intentional contract.
- Keep private parsing and normalization helpers in the same module as the service when they exist only to support that boundary.

```ts
import { Context, Effect, Layer, Schema } from "effect";

export interface VcsProcessOutput {
  readonly stdout: string;
  readonly stderr: string;
}

export class VcsProcessError extends Schema.TaggedErrorClass<VcsProcessError>()("VcsProcessError", {
  detail: Schema.String,
}) {}

export interface VcsProcessShape {
  readonly run: (input: {
    readonly operation: string;
    readonly command: string;
    readonly args: ReadonlyArray<string>;
    readonly cwd: string;
    readonly timeoutMs: number;
  }) => Effect.Effect<VcsProcessOutput, VcsProcessError>;
}

export class VcsProcess extends Context.Service<VcsProcess, VcsProcessShape>()(
  "app/vcs/VcsProcess",
) {}

export class GitHubCliError extends Schema.TaggedErrorClass<GitHubCliError>()("GitHubCliError", {
  operation: Schema.String,
  detail: Schema.String,
}) {}

export interface GitHubCliShape {
  readonly execute: (input: {
    readonly cwd: string;
    readonly args: ReadonlyArray<string>;
    readonly timeoutMs?: number;
  }) => Effect.Effect<VcsProcessOutput, GitHubCliError>;

  readonly createPullRequest: (input: {
    readonly cwd: string;
    readonly baseBranch: string;
    readonly headSelector: string;
    readonly title: string;
    readonly bodyFile: string;
  }) => Effect.Effect<void, GitHubCliError>;
}

export class GitHubCli extends Context.Service<GitHubCli, GitHubCliShape>()(
  "app/source-control/GitHubCli",
) {}

const normalizeGitHubCliError = (operation: string, error: VcsProcessError) =>
  new GitHubCliError({ operation, detail: error.detail });

export const makeGitHubCli = Effect.fnUntraced(function* () {
  const process = yield* VcsProcess;

  const execute: GitHubCliShape["execute"] = (input) =>
    process
      .run({
        operation: "GitHubCli.execute",
        command: "gh",
        args: input.args,
        cwd: input.cwd,
        timeoutMs: input.timeoutMs ?? 30_000,
      })
      .pipe(Effect.mapError((error) => normalizeGitHubCliError("execute", error)));

  return GitHubCli.of({
    execute,
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

export const GitHubCliLayer: Layer.Layer<GitHubCli, never, VcsProcess> = Layer.effect(
  GitHubCli,
  makeGitHubCli(),
);
```

Example pattern:

## Keep services modular, testable, and maintainable

### Split the contract from wiring

A maintainable service module usually has:

1. domain types and typed errors,
2. a `Shape` interface,
3. the `Context.Service` class,
4. a `make` effect or `layerNoDeps`,
5. one or more layers that wire dependencies.

Use `layerNoDeps` when the service should be composed by a larger application layer. Use `layer` for the default fully wired provider. Final live layers should be explicitly typed as `Layer.Layer<ProvidedServices>`.

```ts
import { Context, Effect, Layer, Option, Schema } from "effect";

export interface User {
  readonly id: string;
  readonly name: string;
}

export class UserRepositoryError extends Schema.TaggedErrorClass<UserRepositoryError>()(
  "UserRepositoryError",
  {
    reason: Schema.Literals(["StorageUnavailable"]),
    detail: Schema.String,
  },
) {}

export interface SqlClientShape {
  readonly findUser: (id: string) => Effect.Effect<Option.Option<User>, UserRepositoryError>;
}

export class SqlClient extends Context.Service<SqlClient, SqlClientShape>()("myapp/SqlClient") {}

export interface UserRepositoryShape {
  readonly findById: (id: string) => Effect.Effect<Option.Option<User>, UserRepositoryError>;
}

export class UserRepository extends Context.Service<UserRepository, UserRepositoryShape>()(
  "myapp/UserRepository",
) {
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
      Layer.succeed(SqlClient, SqlClient.of({ findUser: () => Effect.succeed(Option.none()) })),
    ),
  );
}
```

### Capture dependencies once in `make`

For larger services, capture dependencies in `make` and return methods that close over them. This keeps method bodies focused while still making dependencies explicit.

```ts
import { Context, Duration, Effect, Layer, Option, Schema } from "effect";

export interface ProcessRunInput {
  readonly command: string;
  readonly args: ReadonlyArray<string>;
  readonly timeout?: Duration.Input;
}

export interface ProcessRunOutput {
  readonly stdout: string;
  readonly stderr: string;
  readonly timedOut: boolean;
}

export class ProcessTimeoutError extends Schema.TaggedErrorClass<ProcessTimeoutError>()(
  "ProcessTimeoutError",
  {
    command: Schema.String,
    timeoutMs: Schema.Number,
  },
) {}

export interface ProcessSpawnerShape {
  readonly run: (input: ProcessRunInput) => Effect.Effect<ProcessRunOutput>;
}

export class ProcessSpawner extends Context.Service<ProcessSpawner, ProcessSpawnerShape>()(
  "app/process/ProcessSpawner",
) {}

export interface ProcessRunnerShape {
  readonly run: (input: ProcessRunInput) => Effect.Effect<ProcessRunOutput, ProcessTimeoutError>;
}

export class ProcessRunner extends Context.Service<ProcessRunner, ProcessRunnerShape>()(
  "app/process/ProcessRunner",
) {}

const finalizeRunProcess = (
  effect: Effect.Effect<ProcessRunOutput>,
  input: ProcessRunInput,
): Effect.Effect<ProcessRunOutput, ProcessTimeoutError> => {
  const timeout = Duration.fromInputUnsafe(input.timeout ?? "60 seconds");

  return effect.pipe(
    Effect.timeoutOption(timeout),
    Effect.flatMap((result) =>
      Option.isSome(result)
        ? Effect.succeed(result.value)
        : Effect.fail(
            new ProcessTimeoutError({
              command: input.command,
              timeoutMs: Duration.toMillis(timeout),
            }),
          ),
    ),
  );
};

export const makeProcessRunner = Effect.fnUntraced(function* () {
  const spawner = yield* ProcessSpawner;

  return ProcessRunner.of({
    run: (input) => finalizeRunProcess(spawner.run(input), input),
  });
});

export const ProcessRunnerLayer: Layer.Layer<ProcessRunner, never, ProcessSpawner> = Layer.effect(
  ProcessRunner,
  makeProcessRunner(),
);
```

Example pattern:

### Use layer factories for parameterized resources

When a service needs test options, configuration, or a resource handle, expose a function that returns a layer.

```ts
import { Context, Effect, Layer, Ref } from "effect";

export interface GraphqlTestServerShape {
  readonly endpoint: string;
  readonly requests: Effect.Effect<ReadonlyArray<string>>;
  readonly clearRequests: Effect.Effect<void>;
}

export interface GraphqlTestServerOptions {
  readonly path: string;
}

const serveGraphqlTestServer = (
  options: GraphqlTestServerOptions,
): Effect.Effect<GraphqlTestServerShape> =>
  Effect.gen(function* () {
    const requests = yield* Ref.make<ReadonlyArray<string>>([]);

    return {
      endpoint: `http://127.0.0.1${options.path}`,
      requests: Ref.get(requests),
      clearRequests: Ref.set(requests, []),
    };
  });

export class GraphqlTestServer extends Context.Service<GraphqlTestServer, GraphqlTestServerShape>()(
  "@app/plugin-graphql/testing/GraphqlTestServer",
) {
  static readonly layer = (options: GraphqlTestServerOptions): Layer.Layer<GraphqlTestServer> =>
    Layer.effect(GraphqlTestServer, serveGraphqlTestServer(options));
}
```

Example pattern:

### Use scoped acquisition for owned resources

If a service owns a resource with a lifetime, acquire and release it in the layer with `Effect.acquireRelease`, `Layer.scoped`, or an effect passed to `Layer.effect` that contains acquisition and finalization.

```ts
import { Context, Effect, Layer } from "effect";

export interface TestHarness {
  readonly run: Effect.Effect<void>;
  readonly close: Effect.Effect<void>;
}

export class TestHarnessService extends Context.Service<TestHarnessService, TestHarness>()(
  "app/testing/TestHarness",
) {}

const makeTestHarness: Effect.Effect<TestHarness> = Effect.acquireRelease(
  Effect.sync(() => ({
    run: Effect.void,
    close: Effect.void,
  })),
  (harness) => harness.close,
);

export const makeTestHarnessLayer = (): Layer.Layer<TestHarnessService> =>
  Layer.effect(TestHarnessService, makeTestHarness);
```

Example pattern:

### Provide small test services

Prefer test layers over global mocks. Test services can use `Ref`, `Queue`, `PubSub`, or in-memory repositories while preserving the production contract.

```ts
import { Array, Context, Effect, Layer, Ref } from "effect";

export interface Todo {
  readonly id: number;
  readonly title: string;
}

export class TodoRepoTestRef extends Context.Service<
  TodoRepoTestRef,
  Ref.Ref<ReadonlyArray<Todo>>
>()("app/TodoRepoTestRef") {
  static readonly layer: Layer.Layer<TodoRepoTestRef> = Layer.effect(
    TodoRepoTestRef,
    Ref.make(Array.empty<Todo>()),
  );
}

export interface TodoRepoShape {
  readonly create: (title: string) => Effect.Effect<Todo>;
  readonly list: Effect.Effect<ReadonlyArray<Todo>>;
}

export class TodoRepo extends Context.Service<TodoRepo, TodoRepoShape>()("app/TodoRepo") {
  static readonly layerTest: Layer.Layer<TodoRepo | TodoRepoTestRef> = Layer.effect(
    TodoRepo,
    Effect.gen(function* () {
      const store = yield* TodoRepoTestRef;

      const create = Effect.fnUntraced(function* (title: string) {
        const todos = yield* Ref.get(store);
        const todo = { id: todos.length + 1, title };
        yield* Ref.set(store, [...todos, todo]);
        return todo;
      });

      return TodoRepo.of({ create, list: Ref.get(store) });
    }),
  ).pipe(Layer.provideMerge(TodoRepoTestRef.layer));
}
```

For very small behavior tests, `Layer.mock(Service)` can provide a partial service. Missing members intentionally fail when called, so this is only appropriate when the test proves the path uses a narrow capability.

```ts
import { Context, Effect, Layer, Stream } from "effect";

class ExampleService extends Context.Service<
  ExampleService,
  {
    readonly one: Effect.Effect<number>;
    readonly two: () => Effect.Effect<number>;
    readonly events: Stream.Stream<number>;
  }
>()("ExampleService") {}

const program = Effect.gen(function* () {
  const service = yield* ExampleService;
  return yield* service.one;
}).pipe(
  Effect.provide(
    Layer.mock(ExampleService)({
      one: Effect.succeed(123),
    }),
  ),
);
```

## Error handling patterns

- Services must expose typed errors for actionable failures that callers can handle.
- Prefer `Schema.TaggedErrorClass` for app errors so callers can use `Effect.catchTag` / `Effect.catchTags` and schemas can describe the error shape.
- If a tagged error has a `reason`, use `Schema.Literals(...)` with PascalCase values.
- Map lower-level errors to service-level errors inside the service method or adapter boundary.
- Non-actionable failures should remain defects or be converted to defects at the service definition, not exposed as generic `UnknownError` / `InternalError` service failures.
- Do not widen service methods to `Effect<A, unknown>`. Keep expected failures precise.
- Do not throw, use raw `Promise`, or use `async` service methods for expected failures. Use `Effect.try`, `Effect.tryPromise`, `Schema.decodeEffect`, and typed errors.
- When converting a full `Cause` to text for a response or event, use `Cause.pretty(...)` instead of bespoke failure-to-message helpers.

```ts
import { Context, Effect, Schema } from "effect";
import { HttpClient, HttpClientResponse } from "effect/unstable/http";

export class Todo extends Schema.Class<Todo>("Todo")({
  id: Schema.Number,
  title: Schema.String,
  completed: Schema.Boolean,
}) {}

export class TodoApiError extends Schema.TaggedErrorClass<TodoApiError>()("TodoApiError", {
  reason: Schema.Literals(["RequestFailed", "InvalidResponse"]),
  detail: Schema.String,
}) {}

export interface TodoApiShape {
  readonly getTodo: (id: number) => Effect.Effect<Todo, TodoApiError>;
}

export class TodoApi extends Context.Service<TodoApi, TodoApiShape>()("app/TodoApi") {}

export const makeTodoApi = Effect.fnUntraced(function* () {
  const client = yield* HttpClient.HttpClient;

  const getTodo = Effect.fnUntraced(function* (id: number) {
    return yield* client.get(`/todos/${id}`).pipe(
      Effect.flatMap(HttpClientResponse.schemaBodyJson(Todo)),
      Effect.mapError(
        (cause) =>
          new TodoApiError({
            reason: "RequestFailed",
            detail: cause._tag,
          }),
      ),
    );
  });

  return TodoApi.of({ getTodo });
});
```

## Accessing services

Prefer yielding services inside effect bodies:

```ts
const program = Effect.gen(function* () {
  const notifications = yield* Notifications;
  yield* notifications.notify("hello");
  yield* notifications.notify("world");
});
```

Use `Service.use` or `Service.useSync` only for short one-liners:

```ts
const notifyOnce = Notifications.use((notifications) => notifications.notify("hello"));
const configuredPort = ConfigService.useSync((config) => config.port);
```

`Context.Service` implements `use` and `useSync` in `repos/effect/packages/effect/src/Context.ts`, but `repos/effect/migration/services.md` recommends `yield*` for most workflows because it keeps dependencies visible.

## What to avoid

- Do not create giant service bags. Split by behavior boundary and compose layers.
- Do not pass service implementations as function arguments. Yield required services from context inside effect bodies.
- Do not expose low-level dependencies through high-level service shapes unless callers truly need them.
- Do not create stateful globals outside layers. Use `Layer`, `Ref`, `Queue`, `PubSub`, `Scope`, and finalizers so tests can replace and tear down services safely.
- Do not use `Context.Service(..., { make })` expecting it to auto-wire dependencies or create a layer.
- Do not use direct `JSON.parse` / `JSON.stringify` at implementation boundaries. Use `Schema.fromJsonString(...)` codecs.
- Do not use web `fetch` / `Response` at package boundaries. Prefer first-party Effect HTTP services.
- Do not expose generic failures like `XFailed`, `UnknownError`, or `InternalError` from service methods.
- Do not use `Effect.orDie`; handle typed errors with `Effect.catchTag` / `Effect.catchTags`, then `Effect.die` only for genuinely unrecoverable failures.
- Do not erase errors with `unknown`, `any`, broad catches, or untyped defects.
- Do not use non-null assertions or type assertions in service shapes or implementations.
- Do not overuse `Service.use` for workflows. Prefer `yield* Service` in `Effect.gen`.
