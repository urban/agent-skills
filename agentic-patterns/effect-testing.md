# Effect testing patterns for agents

These patterns are distilled from:

- `repos/effect/packages/vitest` and `repos/effect/ai-docs/src/09_testing`
- Effect package tests such as `repos/effect/packages/effect/test/TestClock.test.ts`, `Layer.test.ts`, `Cache.test.ts`, and `unstable/http/HttpClient.test.ts`
- Effect-style tests in `repos/executor`, especially plugin, HTTP, OAuth refresh, and connection tests
- Effect-style tests in `repos/t3code`, especially process, source-control, SSH, and rule-fixture tests
- `repos/alchemy-effect` testing docs, which wrap Vitest tests with Effect-aware setup for provider lifecycle tests

Examples below are copied or adapted from those repositories, then adjusted for this project's stricter rules: no `any`, no non-null assertions, no unchecked type assertions, no expected failures as defects, and no wall-clock sleeps for deterministic Effect tests.

## First principles

- Import test APIs from `@effect/vitest` whenever the test runs Effect code.
- Prefer `it.effect(...)` for normal Effect tests. Return an `Effect`; do not call `Effect.runPromise` inside a test.
- Use `Effect.gen` for multi-step tests and keep assertions close to the Effect step that produced the value.
- Test behavior through the same public boundary a caller uses: service methods, typed clients, streams, CLI/process services, or HTTP APIs.
- Keep production composition intact. Replace only true external boundaries with `Layer.mock`, `Layer.succeed`, in-memory stores, in-process HTTP handlers, or scripted process handles.
- Use deterministic coordination. Use `TestClock`, `Ref`, `Deferred`, `Queue`, scoped fibers, and in-process handlers instead of sleeps, timers, or uncontrolled external state.
- Expected failures belong in the typed error channel. Assert tagged errors with `Effect.flip`, `Effect.exit`, or `Effect.result`.

## Basic `@effect/vitest` shape

Adapted from `repos/effect/ai-docs/src/09_testing/10_effect-tests.ts` and `repos/effect/packages/vitest/test/index.test.ts`:

```ts
import { assert, describe, it } from "@effect/vitest";
import { Effect, Fiber, Schema } from "effect";
import { TestClock } from "effect/testing";

describe("normalization", () => {
  it.effect.each([
    { input: " Ada ", expected: "ada" },
    { input: " Lin ", expected: "lin" },
  ])("normalizes %#", ({ input, expected }) =>
    Effect.gen(function* () {
      assert.strictEqual(input.trim().toLowerCase(), expected);
    }),
  );

  it.effect("controls sleeping fibers with TestClock", () =>
    Effect.gen(function* () {
      const fiber = yield* Effect.forkChild(Effect.sleep("1 minute").pipe(Effect.as("done")));

      yield* TestClock.adjust("1 minute");

      assert.strictEqual(yield* Fiber.join(fiber), "done");
    }),
  );

  it.effect.prop("trimming twice is idempotent", [Schema.String], ([value]) =>
    Effect.gen(function* () {
      assert.strictEqual(value.trim().trim(), value.trim());
    }),
  );
});
```

Use `it.live(...)` only when the test intentionally needs live runtime services, real time, live logging, or a harness that cannot run with the test clock. `@effect/vitest` provides test services to `it.effect` by default.

## Layer-driven tests

`@effect/vitest` exposes `layer(...)` and nested `it.layer(...)`. The Effect repo uses these to share a layer for a test block and release it after the block. The layer receives test services unless `{ excludeTestServices: true }` is passed.

Adapted from `repos/effect/packages/vitest/test/index.test.ts`:

```ts
import { expect, layer } from "@effect/vitest";
import { Context, Effect, Layer } from "effect";

class Foo extends Context.Service<Foo, "foo">()("Foo") {
  static readonly Live = Layer.succeed(Foo, "foo");
}

class Bar extends Context.Service<Bar, "bar">()("Bar") {
  static readonly Live = Layer.effect(
    Bar,
    Effect.map(Foo, () => "bar"),
  );
}

layer(Foo.Live)("Foo", (it) => {
  it.effect("adds Foo to context", () =>
    Effect.gen(function* () {
      const foo = yield* Foo;
      expect(foo).toEqual("foo");
    }),
  );

  it.layer(Bar.Live)("Bar", (it) => {
    it.effect("keeps outer context while adding nested context", () =>
      Effect.gen(function* () {
        const foo = yield* Foo;
        const bar = yield* Bar;

        expect(foo).toEqual("foo");
        expect(bar).toEqual("bar");
      }),
    );
  });
});
```

Guidelines:

- Use `layer(TestLayer)(...)` when all tests in the block intentionally share expensive setup or scoped resources.
- Prefer per-test layers when mutable fake state must be isolated.
- Use nested `it.layer(...)` to add dependencies for a smaller set of tests.
- Use `{ excludeTestServices: true }` only when live clock/random/runtime services are part of the behavior under test.

## Behavior encapsulation

A test should describe and exercise an observable capability, not the implementation path.

Good Effect tests usually look like this:

- Yield the domain service from context and call its public method.
- Inject a fake process runner, HTTP client, clock, secret store, or repository at the boundary.
- Assert the public return value, typed error, emitted event, request payload, process arguments, or persisted row.
- Keep internal refs, queues, caches, spans, and layers private unless they are deliberately exposed as test harness services.

Patterns seen in `repos/t3code` and `repos/executor`:

- Source-control providers are tested through provider-neutral methods while only the GitHub/GitLab/Azure CLI boundary is mocked.
- OpenAPI and GraphQL plugins are tested by creating a real executor with test config, then invoking tools through the executor API.
- Process and SSH tests inject `ChildProcessSpawner` but call the higher-level command/tunnel API.
- HTTP tests use in-process servers or handler-backed clients when the contract is HTTP behavior, not the public internet.

## Modular, testable services

Services stay maintainable when tests can swap boundaries without rebuilding business logic by hand.

Follow these service guidelines:

- Define behavior with `Context.Service` and small domain-oriented shapes.
- Yield services from context inside effects; do not pass service instances through every function.
- Keep real I/O behind boundary services: process spawners, repositories, HTTP clients, speech/LLM clients, audio devices, or storage providers.
- Build live layers by composing focused layers at the edge.
- Build test layers with `Layer.mock`, `Layer.succeed`, in-memory `Ref`s, and scripted handlers.
- Use `Layer.provideMerge` when tests should access both the service under test and its test backing store.

Adapted from `repos/effect/ai-docs/src/09_testing/20_layer-tests.ts`:

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

Adapted from `repos/t3code/packages/tailscale/src/tailscale.test.ts` and `repos/t3code/packages/ssh/src/command.test.ts`:

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

Adapted from `repos/t3code/apps/server/src/sourceControl/GitHubSourceControlProvider.test.ts`:

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

## Time, fibers, and concurrent behavior

Effect's own tests and `repos/t3code` use `TestClock` to prove timeout and retry behavior without waiting on wall-clock time.

Adapted from `repos/effect/packages/effect/test/TestClock.test.ts` and `repos/t3code/packages/ssh/src/command.test.ts`:

```ts
import { assert, it } from "@effect/vitest";
import { Duration, Effect, Fiber, Result } from "effect";
import { TestClock } from "effect/testing";

it.effect("fails commands that never finish", () =>
  Effect.gen(function* () {
    const fiber = yield* Effect.forkChild(
      Effect.result(runCommand({ command: "ssh", args: ["devbox"], timeout: Duration.millis(1) })),
    );

    yield* Effect.yieldNow;
    yield* TestClock.adjust(Duration.millis(1));

    const result = yield* Fiber.join(fiber);

    assert.isTrue(Result.isFailure(result));
    if (Result.isFailure(result)) {
      assert.include(result.failure.message, "timed out");
    }
  }).pipe(Effect.provide(TestProcessLayer)),
);
```

Rules:

- Fork long-running effects with `Effect.forkChild` or `Effect.forkScoped` so they are interrupted by the test scope.
- Call `Effect.yieldNow` before advancing `TestClock` when a forked fiber must reach `sleep`, `timeout`, or a scheduled retry first.
- Use `TestClock.adjust(...)` or `TestClock.setTime(...)`; do not wait on wall-clock sleeps.
- For concurrency contracts, use `Effect.all(..., { concurrency: "unbounded" })`, then assert the behavioral invariant such as one refresh call, shared cached connection, or all callers receiving the same value.

## HTTP and external integration tests

`repos/executor` shows two useful HTTP patterns:

1. Use an in-process server or handler when testing protocol behavior.
2. Provide the client through a layer so application code still depends on `HttpClient.HttpClient`.

Adapted from `repos/executor/packages/plugins/openapi/src/testing/index.ts` and OpenAPI plugin tests:

```ts
import { expect, layer } from "@effect/vitest";
import { Context, Effect, Layer, Predicate, Schema } from "effect";
import { HttpClient, HttpServer } from "effect/unstable/http";

class TestServerAddressError extends Schema.TaggedErrorClass<TestServerAddressError>()(
  "TestServerAddressError",
  { address: Schema.String },
) {}

interface TestServerShape {
  readonly baseUrl: string;
  readonly httpClientLayer: Layer.Layer<HttpClient.HttpClient>;
}

class TestServer extends Context.Service<TestServer, TestServerShape>()("app/TestServer") {
  static readonly layer = Layer.effect(
    TestServer,
    Effect.gen(function* () {
      const server = yield* HttpServer.HttpServer;
      const address = server.address;

      if (!Predicate.isTagged("TcpAddress")(address)) {
        return yield* new TestServerAddressError({ address: "non-tcp" });
      }

      const client = yield* HttpClient.HttpClient;

      return TestServer.of({
        baseUrl: `http://127.0.0.1:${address.port}`,
        httpClientLayer: Layer.succeed(HttpClient.HttpClient, client),
      });
    }),
  );
}

layer(TestServer.layer)("tool invocation", (it) => {
  it.effect("routes requests through the provided HttpClient", () =>
    Effect.gen(function* () {
      const server = yield* TestServer;
      const result = yield* invokeTool({ baseUrl: server.baseUrl }).pipe(
        Effect.provide(server.httpClientLayer),
      );

      expect(result).toEqual({ ok: true });
    }),
  );
});
```

Use a real external service only for an explicitly named integration or smoke test, and gate it with configuration so normal checks are deterministic.

## Error handling patterns

Implementation code should expose actionable failures as tagged errors. Tests should assert the typed failure channel, not thrown exceptions or defects.

Use `Effect.flip` when the operation must fail with one typed error:

```ts
import { assert, it } from "@effect/vitest";
import { Effect, Schema } from "effect";

class RepositoryNotFound extends Schema.TaggedErrorClass<RepositoryNotFound>()(
  "RepositoryNotFound",
  { id: Schema.String },
) {}

it.effect("surfaces a typed not-found error", () =>
  Effect.gen(function* () {
    const service = yield* RepositoryService;

    const error = yield* service.getRepository({ id: "missing" }).pipe(Effect.flip);

    assert.strictEqual(error._tag, "RepositoryNotFound");
    assert.strictEqual(error.id, "missing");
  }).pipe(Effect.provide(RepositoryService.layerTest)),
);
```

Use `Effect.exit` when both success and failure are meaningful observations or when testing a public envelope. This appears often in `repos/executor` failure-mode tests:

```ts
import { expect, it } from "@effect/vitest";
import { Effect, Exit } from "effect";

it.effect("upstream 500 is observable and never a silent success", () =>
  Effect.gen(function* () {
    const exit = yield* invokeRemoteTool().pipe(Effect.exit);

    const text = Exit.match(exit, {
      onFailure: (cause) => String(cause),
      onSuccess: (value) => JSON.stringify(value),
    });

    expect(text).toMatch(/500|response|error/i);
    expect(text.startsWith('{"data":')).toBe(false);
  }),
);
```

Use `Effect.result` when the test is about success/failure classification rather than a specific `Cause`:

```ts
import { assert, it } from "@effect/vitest";
import { Effect, Result } from "effect";

it.effect("idempotent remove succeeds even when the row is absent", () =>
  Effect.gen(function* () {
    const result = yield* service.remove({ id: "already-gone" }).pipe(Effect.result);

    assert.isTrue(Result.isSuccess(result));
  }),
);
```

Error guidelines:

- Define actionable application errors with `Schema.TaggedErrorClass` values with a stable `_tag` and useful fields.
- If an error has a `reason`, model it with `Schema.Literals(...)` using PascalCase reason values.
- In `Effect.gen`, fail with `return yield* new MyError(...)` so control flow and types are clear.
- Recover with `Effect.catchTag` or `Effect.catchTags` when a caller can handle the error.
- Use `Effect.die` only for genuinely unrecoverable defects, not expected domain failures.
- Do not erase error channels to `unknown` just to make a test compile.

## Regression and contract tests

The strongest tests in `repos/executor` are regression tests that encode user-visible contracts:

- non-JSON request bodies must not serialize as `[object Object]`
- OAuth refresh must dedupe concurrent refreshes into one token call
- secret and connection usage must respect scope isolation
- upstream 4xx/5xx responses must remain observable to callers
- removing a shadowed source must not delete the inherited source

Use this pattern for bugs in this project:

1. Name the test after the broken user-visible behavior.
2. Build the closest public composition that can reproduce it.
3. Fake only the boundary that would be external, expensive, or nondeterministic.
4. Assert the stable contract, not every intermediate step.
5. Keep a short comment only when it explains why the regression matters.

## Alchemy-style harness pattern

`repos/alchemy-effect` wraps Effect tests in a file-level harness. The important transferable idea is not the exact API, but the fixture ownership:

- A single `Test.make(...)` owns providers, state, setup hooks, teardown hooks, and helper functions.
- Shared setup returns lazy accessors used inside tests, rather than global mutable values.
- Provider lifecycle tests use scratch in-memory state per test.
- End-to-end stack tests can use persistent state intentionally, then destroy conditionally in CI.

For this project, prefer a small local fixture helper when many tests need the same live composition. The helper should return Effects and Layers, not already-running promises.

## What to avoid

- Do not import from `vitest` for Effect tests when `@effect/vitest` can run the Effect directly.
- Do not call `Effect.runPromise` inside `it.effect`.
- Do not use arbitrary sleeps, timers, real polling, or timing races.
- Do not mock every dependency. Replace true boundaries only.
- Do not assert private refs, queues, caches, span names, layer internals, or exact sequencing unless they are the public contract.
- Do not accidentally share mutable state through `layer(...)`; reset state or build a per-test layer when isolation matters.
- Do not commit focused/skipped tests such as `it.effect.only` or `it.effect.skip` unless there is an explicit temporary reason.
- Do not use `any`, non-null assertions, unchecked type assertions, or `null` in new tests.
- Do not probe errors with ad hoc `_tag` existence checks. Typed Effect error channels should already tell the test what can fail.
- Do not use `Effect.orDie` or defects for expected failures.
- Do not parse or stringify JSON in implementation boundaries. Use Schema codecs there; tests may provide encoded fixture strings when the public boundary consumes encoded data.
- Do not hit real external services in unit or contract tests. Use handler-backed clients, in-process servers, fake process spawners, temporary files, in-memory stores, or clearly marked integration tests.
