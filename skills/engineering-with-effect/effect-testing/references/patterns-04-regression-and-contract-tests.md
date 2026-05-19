# Effect testing patterns for agents — part 4

Covers:

- Regression and contract tests
- Harness pattern
- What to avoid

---

## Regression and contract tests

The strongest regression tests encode user-visible contracts:

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

## Harness pattern

For larger test suites, a file-level harness can own fixtures. The important idea is fixture ownership:

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
