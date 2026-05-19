---
name: effect-testing
description: Test Effect code with @effect/vitest, behavior-first public boundaries, layer replacement, deterministic clocks/fibers/queues, typed error assertions, and in-process integration seams. Use when writing or reviewing tests for Effect services, layers, streams, HTTP APIs, process boundaries, workflows, retries, concurrency, typed failures, or regressions.
---

## Native Effect Standards

- Import test APIs from `@effect/vitest` whenever the test runs Effect code.
- Prefer `it.effect(...)` for normal Effect tests. Return an `Effect`; do not call `Effect.runPromise` inside a test.
- Use `Effect.gen` for multi-step tests and keep assertions close to the Effect step that produced the value.
- Test behavior through the same public boundary a caller uses: service methods, typed clients, streams, CLI/process services, or HTTP APIs.
- Keep production composition intact. Replace only true external boundaries with `Layer.mock`, `Layer.succeed`, in-memory stores, in-process HTTP handlers, or scripted process handles.
- Use deterministic coordination. Use `TestClock`, `Ref`, `Deferred`, `Queue`, scoped fibers, and in-process handlers instead of sleeps, timers, or uncontrolled external state.
- Expected failures belong in the typed error channel. Assert tagged errors with `Effect.flip`, `Effect.exit`, or `Effect.result`.
- Keep behavior behind domain services, layers, schemas, or pure helpers as appropriate because callers should depend on product capabilities, not low-level Effect plumbing.

## Anti-Patterns to Avoid

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
- Do not import from vendored reference repositories; use them only as read-only evidence when the current project has them.
- Do not invent generic `UnknownError`, `InternalError`, or stringly failures when the pattern calls for precise tagged errors.

## Knowledge Boundaries

Design facts this knowledge expects the agent to consider:

- public behavior or regression contract
- service/API/stream/process/workflow boundary under test
- external boundaries to replace
- smallest relevant test command and wider verification scope

Effect-native code should tend toward:

- `@effect/vitest` tests that return Effects
- focused layer-based test compositions
- deterministic coordination with test services
- typed success/failure assertions and regression coverage

Applies to:

- applying Effect testing patterns to implementation, refactoring, review, or tests
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

- Bundled `references/patterns-*` files contain source-pattern detail for designing Effect tests, replacing boundaries, or testing time/concurrency.
- Use `it.effect`, `it.effect.each`, `it.effect.prop`, `layer`, and `it.layer` for Effect code instead of manually running promises inside tests.
- Exercise the public caller-visible boundary and replace only true external systems or nondeterministic services.
- Keep production composition intact and inject fakes through layers, handler-backed clients, fake process spawners, in-memory stores, or scoped fixtures.
- Use `TestClock`, `Ref`, `Deferred`, `Queue`, scoped fibers, and in-process servers instead of sleeps or global state.
- Assert expected failures with `Effect.flip`, `Effect.exit`, or `Effect.result`, preserving tagged error channels.
- Name regression tests after the user-visible contract and broaden verification after focused checks pass.

## Gotchas

- If Effect tests call `Effect.runPromise`, test services, interruption, and causes can be bypassed. Return the `Effect` from `it.effect`.
- If every collaborator is mocked, the test proves a fake architecture. Replace only true process, network, time, storage, or external-system boundaries.
- If tests assert private refs, queues, cache internals, or incidental call order, harmless refactors break the suite. Assert public outcomes and contracts.
- If timing uses wall-clock sleeps, races hide on fast machines and fail in CI. Use `TestClock`, `yieldNow`, `Deferred`, and scoped fibers.
- If mutable fake state is shared through a block layer unintentionally, tests pass or fail by order. Build per-test layers or reset backing `Ref`s.
- If expected failures are turned into defects, tests cannot verify recovery behavior. Keep typed errors and assert tags/reasons directly.

## References

- [`references/patterns-01-effect-testing-patterns-for-agents.md`](./references/patterns-01-effect-testing-patterns-for-agents.md): Read when: you need source-pattern detail for Effect testing patterns for agents, First principles, Basic @effect/vitest shape.
- [`references/patterns-02-modular-testable-services.md`](./references/patterns-02-modular-testable-services.md): Read when: you need source-pattern detail for Modular, testable services, Boundary replacement examples, Process boundary.
- [`references/patterns-03-time-fibers-and-concurrent-behavior.md`](./references/patterns-03-time-fibers-and-concurrent-behavior.md): Read when: you need source-pattern detail for Time, fibers, and concurrent behavior, HTTP and external integration tests, Error handling patterns.
- [`references/patterns-04-regression-and-contract-tests.md`](./references/patterns-04-regression-and-contract-tests.md): Read when: you need source-pattern detail for Regression and contract tests, Harness pattern, What to avoid.
