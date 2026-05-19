---
name: effect-fast-check
description: Write property-based tests for Effect code using @effect/vitest, Effect testing FastCheck, schema-derived arbitraries, typed error assertions, and deterministic boundaries. Use when adding or reviewing property tests for Effect services, schema codecs, invariants, round trips, state models, streams, HTTP contracts, or pure helpers in an Effect codebase.
---

## Native Effect Standards

- Use property tests for behavior that should hold for many inputs: round trips, idempotence, monotonicity, invariants, ordering, commutativity, schema generation, and error classification.
- Keep example tests and property tests complementary. Write simple example tests first when they document important cases, then use property tests to challenge invariants and edge cases.
- For Effect code, prefer `it.effect.prop(...)` from `@effect/vitest`. It runs each generated case as an Effect and provides test services such as `TestClock`.
- Import fast-check through Effect: `import { FastCheck } from "effect/testing"`. Avoid importing `fast-check` directly in project tests unless an existing file already does so for non-Effect code.
- Prefer `Schema`-derived arbitraries for domain data. If a schema encodes the valid input space, generate with the schema rather than duplicating constraints in a custom arbitrary.
- Keep generated values deterministic and controlled by fast-check. Do not mix in `Math.random`, wall-clock time, live network calls, or uncontrolled external state.
- Keep properties small. A failing property should point to one invariant, not a broad scenario with many possible failure causes.
- Keep behavior behind domain services, layers, schemas, or pure helpers as appropriate because callers should depend on product capabilities, not low-level Effect plumbing.

## Anti-Patterns to Avoid

- Do not pass raw schemas to non-effectful `it.prop`; use `Schema.toArbitrary(...)` or `it.effect.prop`.
- Do not run Effect programs inside `FastCheck.property` with `Effect.runPromise`. Use `it.effect.prop` so failures, interruption, context, and test services are handled by `@effect/vitest`.
- Do not generate invalid values and then discard most of them with `.filter` or `FastCheck.pre` when a constrained arbitrary or schema can generate valid values directly.
- Do not over-constrain arbitraries just to make examples smaller. Shrinking already gives small counterexamples.
- Do not hide expected failures as defects with `throw`, `Effect.die`, `Effect.orDie`, or `new Error`.
- Do not assert on private implementation details, call counts, logs, spans, or timing races unless they are the behavior under test.
- Do not use property tests against live external services, live AI providers, real clocks, or real networks.
- Do not add a custom property-test wrapper until repeated local patterns justify one. Direct `@effect/vitest` property tests are the default for this project.
- Do not import from vendored reference repositories; use them only as read-only evidence when the current project has them.
- Do not invent generic `UnknownError`, `InternalError`, or stringly failures when the pattern calls for precise tagged errors.

## Knowledge Boundaries

Design facts this knowledge expects the agent to consider:

- the invariant or behavioral law to test
- public boundary or pure helper under test
- schemas or arbitraries for valid domain inputs
- deterministic service layers and test services

Effect-native code should tend toward:

- small property tests that target one invariant
- schema-derived or well-constrained arbitraries
- typed failure assertions when generated values are invalid
- deterministic runs without live services, random side channels, or wall-clock timing

Applies to:

- applying Effect fast-check patterns to implementation, refactoring, review, or tests
- preserving typed Effect success, error, and context channels
- keeping runtime-specific or external-system concerns at explicit boundaries

Does not cover:

- broad rewrites outside the user-requested behavior
- replacing project conventions without evidence from local code or the bundled reference
- live external integrations in normal tests unless the task is explicitly an integration smoke test

Failure modes this knowledge helps avoid:

- leaking low-level Effect or provider/runtime details through domain APIs
- flattening typed errors, causes, or schema failures into unstructured strings
- writing tests that depend on live services, wall-clock timing, or implementation internals

## Best-Practice Patterns

- Bundled `references/patterns-*` files contain source-pattern detail for choosing APIs, schemas, arbitraries, or test boundaries.
- State one invariant, round trip, idempotence, ordering, commutativity, or error-classification property per test.
- Use `it.effect.prop` for Effect code; use `it.prop` only for pure synchronous checks with explicit `Schema.toArbitrary` conversion.
- Prefer schema-derived arbitraries and domain builders over duplicate custom constraints or heavy `.filter` usage.
- Exercise public behavior boundaries and reset or rebuild mutable state for each generated case.
- Assert typed errors with `Effect.flip`, `Effect.exit`, or `Effect.catchTag`; do not hide expected invalid inputs as defects.
- Tune `numRuns` only after the property is cheap, deterministic, and focused.

## Gotchas

- If a property bundles several invariants, the shrunk counterexample still leaves you guessing which contract failed. Split until one property names one law.
- If raw schemas are passed to non-effectful `it.prop`, the test API rejects them or behaves inconsistently. Convert with `Schema.toArbitrary` or use `it.effect.prop`.
- If Effect programs run inside `FastCheck.property` with `Effect.runPromise`, context, interruption, causes, and test services are bypassed. Use `it.effect.prop`.
- If generated values are discarded with broad filters, runs become slow and shrinking gets worse. Generate valid values through constrained schemas or arbitraries.
- If properties hit live services, clocks, networks, or model providers, failures become nondeterministic. Replace boundaries with layers and `TestClock`.
- If expected invalid inputs throw or die, the property tests defects rather than the contract. Keep failures in typed error channels and assert them.

## References

- [`references/patterns-01-effect-fast-check-patterns-for-agents.md`](./references/patterns-01-effect-fast-check-patterns-for-agents.md): Read when: you need source-pattern detail for Effect fast-check patterns for agents, First principles, Behavior encapsulation.
- [`references/patterns-02-schema-arbitraries.md`](./references/patterns-02-schema-arbitraries.md): Read when: you need source-pattern detail for Schema arbitraries, Error handling patterns, General fast-check habits.
