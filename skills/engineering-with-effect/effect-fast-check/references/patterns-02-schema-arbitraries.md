# Effect fast-check patterns for agents — part 2

Covers:

- Schema arbitraries
- Error handling patterns
- General fast-check habits
- What to avoid

---

## Schema arbitraries

`Schema.toArbitrary` and `it.effect.prop` let schemas define the generated input space.

- Use array-form `it.effect.prop("name", [Schema.String], ([value]) => ...)` when you want automatic schema conversion.
- In object-form properties, prefer converting schemas explicitly with `Schema.toArbitrary(...)` for clarity.
- Prefer schema checks over arbitrary filters. For example, use `Schema.Int.check(Schema.isBetween({ minimum: 0, maximum: 100 }))` instead of `FastCheck.integer().filter(...)`.
- Use `TestSchema.Asserts(schema).arbitrary().verifyGeneration()` for schema authorship tests: generated values must satisfy `Schema.is(schema)`.
- Use `TestSchema.Asserts(schema).verifyLosslessTransformation()` for codecs that should encode and decode losslessly.
- Add a `toArbitrary` annotation only when the built-in generator cannot produce useful valid values for a custom declaration or constrained schema.

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

General property-testing patterns are useful, but adapt them to Effect's testing APIs.

- Start with broad arbitraries. Do not add `min`, `max`, `minLength`, or `maxLength` unless those limits are part of the domain or needed for a clear performance reason.
- Prefer generator constraints over `.filter` and `FastCheck.pre`. Use `FastCheck.integer({ min: 1 })`, `FastCheck.nat()`, `Schema.NonEmptyString`, or a `.map(...)` construction when possible.
- Use `FastCheck.pre` only for relationships that are hard to generate directly, such as comparing two distinct values or excluding NaN.
- Construct inputs so the expected property is obvious. Do not rewrite the implementation under test inside the predicate.
- Prefer invariant assertions over exact full-output assertions when the exact output is complex.
- For asynchronous non-Effect code, use `FastCheck.asyncProperty`; for Effect code, use `it.effect.prop` instead.
- Tune `numRuns` intentionally. Increase it for cheap pure invariants; keep it lower for expensive service or schema round-trip tests.

Example pattern:

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
