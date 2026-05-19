# Effect testing patterns for agents — part 1

Covers:

- Effect testing patterns for agents
- First principles
- Basic @effect/vitest shape
- Layer-driven tests
- Behavior encapsulation

---

# Effect testing patterns for agents

## First principles

- Import test APIs from `@effect/vitest` whenever the test runs Effect code.
- Prefer `it.effect(...)` for normal Effect tests. Return an `Effect`; do not call `Effect.runPromise` inside a test.
- Use `Effect.gen` for multi-step tests and keep assertions close to the Effect step that produced the value.
- Test behavior through the same public boundary a caller uses: service methods, typed clients, streams, CLI/process services, or HTTP APIs.
- Keep production composition intact. Replace only true external boundaries with `Layer.mock`, `Layer.succeed`, in-memory stores, in-process HTTP handlers, or scripted process handles.
- Use deterministic coordination. Use `TestClock`, `Ref`, `Deferred`, `Queue`, scoped fibers, and in-process handlers instead of sleeps, timers, or uncontrolled external state.
- Expected failures belong in the typed error channel. Assert tagged errors with `Effect.flip`, `Effect.exit`, or `Effect.result`.

## Basic `@effect/vitest` shape

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

Useful patterns:

- Source-control providers are tested through provider-neutral methods while only the GitHub/GitLab/Azure CLI boundary is mocked.
- Protocol plugins are tested by creating a real test composition, then invoking tools through the public API.
- Process and SSH tests inject `ChildProcessSpawner` but call the higher-level command/tunnel API.
- HTTP tests use in-process servers or handler-backed clients when the contract is HTTP behavior, not the public internet.
