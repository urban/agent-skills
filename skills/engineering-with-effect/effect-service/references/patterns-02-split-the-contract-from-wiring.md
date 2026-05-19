# Effect `Context.Service` patterns for agents — part 2

Covers:

- Split the contract from wiring
- Capture dependencies once in make

---

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
