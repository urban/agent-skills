# Effect fast-check patterns for agents

These notes capture how agents should write property-based tests for Effect code in this project. They are based on:

- `knowledge/skills/effect-fast-check-v4.md`
- `repos/effect/packages/effect/src/testing/FastCheck.ts`
- `repos/effect/packages/effect/src/testing/TestSchema.ts`
- `repos/effect/packages/vitest/src/internal/internal.ts`
- `repos/effect/packages/effect/test/schema/toArbitrary.test.ts`
- `repos/effect/packages/vitest/test/index.test.ts`
- `repos/effect/ai-docs/src/09_testing/10_effect-tests.ts`
- general fast-check patterns from `repos/fast-check/skills/javascript-testing-expert/SKILL.md` and `repos/fast-check/examples/**`

Search note: `repos/alchemy-effect`, `repos/executor`, and `repos/t3code` mostly carry `fast-check` transitively through Effect and do not currently provide many app-level property-test examples. `repos/executor/notes/livestore-effect-testing-porting.md` recommends direct `@effect/vitest` property tests until a custom wrapper is justified.

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

Adapted from `repos/effect/ai-docs/src/09_testing/10_effect-tests.ts`:

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

Service property test adapted from `repos/effect/packages/vitest/test/index.test.ts` layer/property patterns:

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

Use direct `FastCheck.assert(FastCheck.property(...))` only when a file is testing a pure low-level helper and does not need Effect services. This is common in `repos/fast-check` itself and in Effect's schema test helpers.

Adapted from `repos/fast-check/examples/003-misc/roman/main.spec.ts`:

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

## Schema arbitraries

`Schema.toArbitrary` and `it.effect.prop` let schemas define the generated input space.

- Use array-form `it.effect.prop("name", [Schema.String], ([value]) => ...)` when you want automatic schema conversion.
- In object-form properties, prefer converting schemas explicitly with `Schema.toArbitrary(...)` for clarity.
- Prefer schema checks over arbitrary filters. For example, use `Schema.Int.check(Schema.isBetween({ minimum: 0, maximum: 100 }))` instead of `FastCheck.integer().filter(...)`.
- Use `TestSchema.Asserts(schema).arbitrary().verifyGeneration()` for schema authorship tests: generated values must satisfy `Schema.is(schema)`.
- Use `TestSchema.Asserts(schema).verifyLosslessTransformation()` for codecs that should encode and decode losslessly.
- Add a `toArbitrary` annotation only when the built-in generator cannot produce useful valid values for a custom declaration or constrained schema.

Adapted from `repos/effect/packages/effect/test/schema/toArbitrary.test.ts` and `repos/effect/packages/effect/src/testing/TestSchema.ts`:

```ts
import { describe, it } from "vitest";
import { Schema } from "effect";
import { TestSchema } from "effect/testing";

const Score = Schema.Int.check(Schema.isBetween({ minimum: 0, maximum: 100 })).annotate({
  identifier: "Score",
});

describe("Score", () => {
  it("generates valid scores", () => {
    const asserts = new TestSchema.Asserts(Score);
    asserts.arbitrary().verifyGeneration({ params: { numRuns: 100 } });
  });
});
```

Round-trip property for a codec:

```ts
import { assert, it } from "@effect/vitest";
import { Effect, Schema } from "effect";

const AssessmentRecord = Schema.Struct({
  id: Schema.String.check(Schema.isNonEmpty()),
  score: Schema.Int.check(Schema.isBetween({ minimum: 0, maximum: 100 })),
}).annotate({ identifier: "AssessmentRecord" });

it.effect.prop("assessment record JSON round-trips", [AssessmentRecord], ([record]) =>
  Effect.gen(function* () {
    const encoded = yield* Schema.encode(AssessmentRecord)(record);
    const decoded = yield* Schema.decode(AssessmentRecord)(encoded);
    assert.deepStrictEqual(decoded, record);
  }),
);
```

Custom arbitrary annotation pattern adapted from Effect's `toArbitrary` tests:

```ts
import { Schema } from "effect";

const EvenScore = Schema.Int.check(Schema.isBetween({ minimum: 0, maximum: 100 })).annotate({
  identifier: "EvenScore",
  toArbitrary: () => (fc) => fc.integer({ min: 0, max: 50 }).map((n) => n * 2),
});
```

## Error handling patterns

Property tests should keep expected failures in the typed Effect error channel.

- Define actionable failures with `Schema.TaggedErrorClass` and precise `_tag` values.
- If a tagged error has a `reason`, use `Schema.Literals(...)` with PascalCase values.
- In service implementations, return typed errors with `return yield* new MyError(...)` inside `Effect.gen` / `Effect.fnUntraced`.
- In property tests, use `Effect.flip`, `Effect.exit`, or `Effect.catchTag` to assert expected typed failures.
- Do not use `Effect.orDie`, `throw`, `new Error`, or rejected promises to represent expected invalid generated inputs.
- Do not erase error channels to `unknown`; keep properties specific enough to assert the failure contract.

Example:

```ts
import { assert, describe, it } from "@effect/vitest";
import { Context, Effect, Layer, Schema } from "effect";
import { FastCheck } from "effect/testing";

class InvalidScore extends Schema.TaggedErrorClass<InvalidScore>()("InvalidScore", {
  reason: Schema.Literals(["TooLow", "TooHigh"]),
  score: Schema.Number,
}) {}

interface ScorePolicyShape {
  readonly accept: (score: number) => Effect.Effect<number, InvalidScore>;
}

class ScorePolicy extends Context.Service<ScorePolicy, ScorePolicyShape>()(
  "fiberisle/test/ScorePolicy",
) {
  static readonly Test = Layer.succeed(
    ScorePolicy,
    ScorePolicy.of({
      accept: (score) =>
        Effect.gen(function* () {
          if (score < 0) {
            return yield* new InvalidScore({ reason: "TooLow", score });
          }
          if (score > 100) {
            return yield* new InvalidScore({ reason: "TooHigh", score });
          }
          return score;
        }),
    }),
  );
}

describe("ScorePolicy", () => {
  it.layer(ScorePolicy.Test)((it) => {
    it.effect.prop("rejects scores below zero", [FastCheck.integer({ max: -1 })], ([score]) =>
      Effect.gen(function* () {
        const policy = yield* ScorePolicy;
        const error = yield* Effect.flip(policy.accept(score));
        assert.strictEqual(error.reason, "TooLow");
      }),
    );
  });
});
```

## General fast-check habits

The fast-check repo patterns are useful, but adapt them to Effect's testing APIs.

- Start with broad arbitraries. Do not add `min`, `max`, `minLength`, or `maxLength` unless those limits are part of the domain or needed for a clear performance reason.
- Prefer generator constraints over `.filter` and `FastCheck.pre`. Use `FastCheck.integer({ min: 1 })`, `FastCheck.nat()`, `Schema.NonEmptyString`, or a `.map(...)` construction when possible.
- Use `FastCheck.pre` only for relationships that are hard to generate directly, as in `repos/fast-check` tests that compare two distinct values or exclude NaN.
- Construct inputs so the expected property is obvious. Do not rewrite the implementation under test inside the predicate.
- Prefer invariant assertions over exact full-output assertions when the exact output is complex.
- For asynchronous non-Effect code, use `FastCheck.asyncProperty`; for Effect code, use `it.effect.prop` instead.
- Tune `numRuns` intentionally. Increase it for cheap pure invariants; keep it lower for expensive service or schema round-trip tests.

Adapted from `repos/fast-check/packages/fast-check/test/unit/arbitrary/_internals/helpers/FloatHelpers.spec.ts`:

```ts
import { expect, it } from "vitest";
import { FastCheck } from "effect/testing";

const absoluteIndex = (n: number): number => (n < 0 ? -n - 1 : n);

it("absoluteIndex orders non-negative values", () => {
  FastCheck.assert(
    FastCheck.property(FastCheck.nat(), FastCheck.nat(), (a, b) => {
      if (a <= b) {
        expect(absoluteIndex(a)).toBeLessThanOrEqual(absoluteIndex(b));
      } else {
        expect(absoluteIndex(a)).toBeGreaterThanOrEqual(absoluteIndex(b));
      }
    }),
  );
});
```

## What to avoid

- Do not pass raw schemas to non-effectful `it.prop`; use `Schema.toArbitrary(...)` or `it.effect.prop`.
- Do not run Effect programs inside `FastCheck.property` with `Effect.runPromise`. Use `it.effect.prop` so failures, interruption, context, and test services are handled by `@effect/vitest`.
- Do not generate invalid values and then discard most of them with `.filter` or `FastCheck.pre` when a constrained arbitrary or schema can generate valid values directly.
- Do not over-constrain arbitraries just to make examples smaller. Shrinking already gives small counterexamples.
- Do not hide expected failures as defects with `throw`, `Effect.die`, `Effect.orDie`, or `new Error`.
- Do not assert on private implementation details, call counts, logs, spans, or timing races unless they are the behavior under test.
- Do not use property tests against live external services, live AI providers, real clocks, or real networks.
- Do not add a custom property-test wrapper until repeated local patterns justify one. Direct `@effect/vitest` property tests are the default for this project.
