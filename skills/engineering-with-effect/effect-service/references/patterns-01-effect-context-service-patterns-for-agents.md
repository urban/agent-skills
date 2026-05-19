# Effect `Context.Service` patterns for agents — part 1

Covers:

- Effect Context.Service patterns for agents
- First principles
- Encapsulate behavior behind capabilities
- Keep services modular, testable, and maintainable

---

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
