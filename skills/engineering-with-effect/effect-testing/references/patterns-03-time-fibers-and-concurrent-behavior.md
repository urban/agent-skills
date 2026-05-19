# Effect testing patterns for agents — part 3

Covers:

- Time, fibers, and concurrent behavior
- HTTP and external integration tests
- Error handling patterns

---

## Time, fibers, and concurrent behavior

Effect's own tests use `TestClock` to prove timeout and retry behavior without waiting on wall-clock time.

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

Use two HTTP patterns:

1. Use an in-process server or handler when testing protocol behavior.
2. Provide the client through a layer so application code still depends on `HttpClient.HttpClient`.

Example pattern:

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

Use `Effect.exit` when both success and failure are meaningful observations or when testing a public envelope:

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
