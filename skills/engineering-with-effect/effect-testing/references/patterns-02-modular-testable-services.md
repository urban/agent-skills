# Effect testing patterns for agents — part 2

Covers:

- Modular, testable services
- Boundary replacement examples
- Process boundary
- Domain service boundary

---

## Modular, testable services

Services stay maintainable when tests can swap boundaries without rebuilding business logic by hand.

Follow these service guidelines:

- Define behavior with `Context.Service` and small domain-oriented shapes.
- Yield services from context inside effects; do not pass service instances through every function.
- Keep real I/O behind boundary services: process spawners, repositories, HTTP clients, speech/LLM clients, audio devices, or storage providers.
- Build live layers by composing focused layers at the edge.
- Build test layers with `Layer.mock`, `Layer.succeed`, in-memory `Ref`s, and scripted handlers.
- Use `Layer.provideMerge` when tests should access both the service under test and its test backing store.

```ts
import { assert, layer } from "@effect/vitest";
import { Context, Effect, Layer, Ref } from "effect";

interface Todo {
  readonly id: number;
  readonly title: string;
}

class TodoRepoTestRef extends Context.Service<TodoRepoTestRef, Ref.Ref<ReadonlyArray<Todo>>>()(
  "app/TodoRepoTestRef",
) {
  static readonly layer = Layer.effect(TodoRepoTestRef, Ref.make<ReadonlyArray<Todo>>([]));
}

class TodoRepo extends Context.Service<
  TodoRepo,
  {
    readonly create: (title: string) => Effect.Effect<Todo>;
    readonly list: Effect.Effect<ReadonlyArray<Todo>>;
  }
>()("app/TodoRepo") {
  static readonly layerTest = Layer.effect(
    TodoRepo,
    Effect.gen(function* () {
      const store = yield* TodoRepoTestRef;

      const create = Effect.fnUntraced(function* (title: string) {
        const todos = yield* Ref.get(store);
        const todo = { id: todos.length + 1, title };
        yield* Ref.set(store, [...todos, todo]);
        return todo;
      });

      return TodoRepo.of({
        create,
        list: Ref.get(store),
      });
    }),
  ).pipe(Layer.provideMerge(TodoRepoTestRef.layer));
}

layer(TodoRepo.layerTest)("TodoRepo", (it) => {
  it.effect("creates and lists todos through the repo service", () =>
    Effect.gen(function* () {
      const repo = yield* TodoRepo;

      yield* repo.create("Write docs");
      const todos = yield* repo.list;

      assert.deepStrictEqual(
        todos.map((todo) => todo.title),
        ["Write docs"],
      );
    }),
  );
});
```

## Boundary replacement examples

### Process boundary

Example pattern:

```ts
import { assert, it } from "@effect/vitest";
import { Effect, Layer, Sink, Stream } from "effect";
import { ChildProcessSpawner } from "effect/unstable/process";

const encoder = new TextEncoder();

const makeHandle = (stdout: string) =>
  ChildProcessSpawner.makeHandle({
    pid: ChildProcessSpawner.ProcessId(1),
    exitCode: Effect.succeed(ChildProcessSpawner.ExitCode(0)),
    isRunning: Effect.succeed(false),
    kill: () => Effect.void,
    unref: Effect.succeed(Effect.void),
    stdin: Sink.drain,
    stdout: Stream.make(encoder.encode(stdout)),
    stderr: Stream.empty,
    all: Stream.empty,
    getInputFd: () => Sink.drain,
    getOutputFd: () => Stream.empty,
  });

const spawnerLayer = Layer.succeed(
  ChildProcessSpawner.ChildProcessSpawner,
  ChildProcessSpawner.make((command) =>
    Effect.gen(function* () {
      const process = yield* decodeCommand(command);
      assert.strictEqual(process.command, "tailscale");
      assert.deepStrictEqual(process.args, ["status", "--json"]);
      return makeHandle('{"Self":{"DNSName":"desktop.tail.ts.net."}}');
    }),
  ),
);

it.effect("reads status through the process-spawner boundary", () =>
  Effect.gen(function* () {
    const status = yield* readTailscaleStatus.pipe(Effect.provide(spawnerLayer));
    assert.strictEqual(status.magicDnsName, "desktop.tail.ts.net");
  }),
);
```

The important behavior is that the service still runs normally; only the OS process boundary is fake.

### Domain service boundary

Example pattern:

```ts
import { assert, it } from "@effect/vitest";
import { Effect, Layer, Option } from "effect";

const makeProvider = (github: Partial<GitHubCli.GitHubCliShape>) =>
  GitHubSourceControlProvider.make().pipe(Effect.provide(Layer.mock(GitHubCli.GitHubCli)(github)));

it.effect("maps provider-specific pull requests into the common change-request shape", () =>
  Effect.gen(function* () {
    const provider = yield* makeProvider({
      getPullRequest: () =>
        Effect.succeed({
          number: 42,
          title: "Add GitHub provider",
          url: "https://github.example/pull/42",
          baseRefName: "main",
          headRefName: "feature/source-control",
          state: "open",
          isCrossRepository: true,
          headRepositoryNameWithOwner: "fork/repo",
          headRepositoryOwnerLogin: "fork",
        }),
    });

    const changeRequest = yield* provider.getChangeRequest({ cwd: "/repo", reference: "42" });

    assert.deepStrictEqual(changeRequest, {
      provider: "github",
      number: 42,
      title: "Add GitHub provider",
      url: "https://github.example/pull/42",
      baseRefName: "main",
      headRefName: "feature/source-control",
      state: "open",
      updatedAt: Option.none(),
      isCrossRepository: true,
      headRepositoryNameWithOwner: "fork/repo",
      headRepositoryOwnerLogin: "fork",
    });
  }),
);
```

Assert exact calls only when the exact call is the contract: CLI arguments, HTTP method/path/headers, serialized request body, deduped refresh calls, approval prompts, or cleanup calls.
