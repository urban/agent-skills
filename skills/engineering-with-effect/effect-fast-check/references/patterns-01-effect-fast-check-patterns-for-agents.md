# Effect fast-check patterns for agents — part 1

Covers:

- Effect fast-check patterns for agents
- First principles
- Behavior encapsulation
- Modular, testable, maintainable services
- Choosing the property-test API
- it.effect.prop for Effect code
- it.prop for pure synchronous checks
- Direct FastCheck.assert for rare lower-level helpers

---

# Effect fast-check patterns for agents

## First principles

- Use property tests for behavior that should hold for many inputs: round trips, idempotence, monotonicity, invariants, ordering, commutativity, schema generation, and error classification.
- Keep example tests and property tests complementary. Write simple example tests first when they document important cases, then use property tests to challenge invariants and edge cases.
- For Effect code, prefer `it.effect.prop(...)` from `@effect/vitest`. It runs each generated case as an Effect and provides test services such as `TestClock`.
- Import fast-check through Effect: `import { FastCheck } from "effect/testing"`. Avoid importing `fast-check` directly in project tests unless an existing file already does so for non-Effect code.
- Prefer `Schema`-derived arbitraries for domain data. If a schema encodes the valid input space, generate with the schema rather than duplicating constraints in a custom arbitrary.
- Keep generated values deterministic and controlled by fast-check. Do not mix in `Math.random`, wall-clock time, live network calls, or uncontrolled external state.
- Keep properties small. A failing property should point to one invariant, not a broad scenario with many possible failure causes.

## Behavior encapsulation

Property tests should exercise public behavior boundaries, not implementation details.

- Test service methods, pure domain functions, RPC clients, schema codecs, streams, and HTTP contracts through the same API a caller uses.
- Do not expose internals just to make them property-testable. If a private algorithm deserves property tests, extract it as a named pure domain helper with a stable contract.
- Do not put fast-check concerns into production services. Arbitraries belong in tests, test support modules, or schema annotations used by `Schema.toArbitrary`.
- Build valid inputs at the boundary. Use schemas, branded constructors, or test-only builders so the service receives domain values, not arbitrary unchecked objects.
- Avoid property tests that depend on hidden accumulated state unless the property is explicitly about state evolution. For stateful services, generate a command sequence and compare against a simple model, or reset/build state inside each generated case.

```ts
import { assert, describe, it } from "@effect/vitest";
import { Effect, Schema } from "effect";

const normalizeName = (name: string): string => name.trim().toLowerCase();

describe("normalizeName", () => {
  it.effect.prop("is idempotent", [Schema.String], ([name]) =>
    Effect.gen(function* () {
      const once = normalizeName(name);
      const twice = normalizeName(once);
      assert.strictEqual(twice, once);
    }),
  );
});
```

## Modular, testable, maintainable services

Services make property tests easier when their contracts are small and domain-oriented.

- Define services with `Context.Service`; expose methods such as `normalizeTranscript`, `scoreAnswer`, or `loadAssessment`, not raw clients or mutable references.
- Yield dependencies from context inside service construction or method bodies. Do not pass service instances as ordinary function parameters.
- Provide a focused live layer and focused test layers. Tests should swap true external boundaries, not reimplement the whole application graph.
- Keep service methods deterministic for a given set of dependencies. If a method uses time, random values, files, HTTP, or AI providers, depend on Effect services/layers that can be replaced.
- Prefer pure helper functions for pure invariants, then call those helpers from the service. Test both: examples at the service boundary, properties around the pure invariant when useful.
- Do not assert on call counts or private sequencing unless it is part of the public contract. Prefer observable outputs, typed errors, state transitions, or emitted events.

```ts
import { assert, describe, it } from "@effect/vitest";
import { Context, Effect, Layer } from "effect";
import { FastCheck } from "effect/testing";

interface TranscriptNormalizerShape {
  readonly normalize: (input: string) => Effect.Effect<string>;
}

class TranscriptNormalizer extends Context.Service<
  TranscriptNormalizer,
  TranscriptNormalizerShape
>()("fiberisle/test/TranscriptNormalizer") {
  static readonly Test = Layer.succeed(
    TranscriptNormalizer,
    TranscriptNormalizer.of({
      normalize: (input) => Effect.succeed(input.trim().replaceAll(/\s+/g, " ")),
    }),
  );
}

describe("TranscriptNormalizer", () => {
  it.layer(TranscriptNormalizer.Test)((it) => {
    it.effect.prop("normalization is idempotent", [FastCheck.string()], ([input]) =>
      Effect.gen(function* () {
        const service = yield* TranscriptNormalizer;
        const once = yield* service.normalize(input);
        const twice = yield* service.normalize(once);
        assert.strictEqual(twice, once);
      }),
    );
  });
});
```

## Choosing the property-test API

### `it.effect.prop` for Effect code

Use when the predicate returns an `Effect`, needs services, uses `TestClock`, reads refs/queues/streams, or asserts typed errors.

```ts
import { assert, it } from "@effect/vitest";
import { Effect, Schema } from "effect";

it.effect.prop("trimming never increases length", [Schema.String], ([value]) =>
  Effect.gen(function* () {
    assert.isAtMost(value.trim().length, value.length);
  }),
);
```

### `it.prop` for pure synchronous checks

Use only for non-effectful properties. Convert schemas manually with `Schema.toArbitrary`; raw schemas are rejected by non-effectful `it.prop`.

```ts
import { assert, it } from "@effect/vitest";
import { Schema } from "effect";

it.prop("string reverse preserves length", [Schema.toArbitrary(Schema.String)], ([value]) => {
  assert.strictEqual([...value].reverse().length, [...value].length);
});
```

### Direct `FastCheck.assert` for rare lower-level helpers

Use direct `FastCheck.assert(FastCheck.property(...))` only when a file is testing a pure low-level helper and does not need Effect services. This is common in Effect's schema test helpers.

Example pattern:

```ts
import { expect, it } from "vitest";
import { FastCheck } from "effect/testing";

const reverse = (input: ReadonlyArray<number>): ReadonlyArray<number> => [...input].reverse();

it("reversing twice returns the original array", () => {
  FastCheck.assert(
    FastCheck.property(FastCheck.array(FastCheck.integer()), (values) => {
      expect(reverse(reverse(values))).toEqual(values);
    }),
  );
});
```
