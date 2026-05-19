# Effect `Layer` patterns for agents — part 1

Covers:

- Effect Layer patterns for agents
- First principles
- Encapsulate behavior behind services, not layers
- Keep services modular, testable, and maintainable
- Split construction from composition

---

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
