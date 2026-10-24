---
name: effect-testing
description: Choose cross-cutting Effect test seams and deterministic evidence through layer replacement, logical time, concurrency coordination, typed failures, interruption, and cleanup. Use when test boundary or evidence design is the primary decision, rather than merely because implementation work includes tests.
---

## Rules

- Test through the public boundary used by a real caller and preserve production composition behind it.
- Replace only external, expensive, nondeterministic, or destructive boundaries.
- Coordinate concurrency with Effect test services and synchronization primitives, not elapsed wall time.
- Assert stable behavioral outcomes, typed failures, protocol effects, and cleanup obligations.

## Constraints

- A fake must preserve the boundary semantics relevant to the claim; behavior omitted by the fake is not covered by that test.
- Shared test layers may share state; choose sharing only when the suite intends it.
- Live external checks are separately named smoke/integration tests, not normal behavioral tests.

## Knowledge Boundaries

Applies to:

- selecting unit, contract, in-process integration, and live smoke boundaries
- layer replacement and state isolation
- logical time, fibers, queues, deferreds, retries, interruption, and cleanup
- typed success/failure and regression assertions

Does not cover:

- application topology, service contract, or Layer construction decisions merely exercised by a test
- protocol-specific test semantics or transport harness implementation
- property-law and generator design
- mechanically detectable test API misuse
- testing behavior already guaranteed by the compiler or an unwrapped dependency

Decision inputs:

- user-visible or caller-visible contract
- smallest boundary that reproduces the behavior
- nondeterministic capabilities to replace
- coordination point and evidence that the changed path executed

## Patterns

- Build the closest public composition that demonstrates the contract, then replace its true external edges with layers, handler-backed clients, fake spawners, or scoped fixtures.
- Use `it.effect` for scoped tests with virtual time; use `it.live` when the live Effect environment is part of the claim. Neither choice determines whether external services are real or replaced.
- Fork time-driven work before adjusting the clock. Use explicit readiness for application milestones; the test clock's scheduler coordination does not prove that an external request has arrived.
- Assert exact calls only when wire shape or invocation is the contract, such as method/path/body, CLI arguments, idempotency key, or cleanup call.
- Assert typed failures through the error/result/exit shape that callers observe. Inspect Cause when defect or interruption classification matters.
- For regression tests, name the broken behavior, reproduce through the public boundary, and assert the stable outcome that prevents recurrence.
- Escalate verification fidelity when transport, middleware, serialization, lifecycle, or runtime behavior is itself under test.

## Gotchas

- Mocking every collaborator proves a duplicate implementation rather than the production graph.
- A clock adjustment cannot complete a real network request or native JavaScript timer. Replace that edge or await an explicit readiness signal instead of advancing more time.
- A shared block layer can share both fake state and test-clock progress. Use per-test construction for isolation; serial execution alone does not reset state.
- Asserting private refs, queues, cache layout, or incidental call order makes harmless refactors look like regressions.
- An in-memory fake that ignores uniqueness, ordering, transactions, or interruption can validate behavior the real boundary cannot provide.
- A test can finish before its owning scope closes. Assert release after closing a local scope or awaiting interruption, not while the resource is still owned by the test.

## References

- [`references/public-boundaries-and-layers.md`](./references/public-boundaries-and-layers.md): Read when: choosing the test seam, production composition, fake state, or in-process integration boundary.
- [`references/time-concurrency-and-cleanup.md`](./references/time-concurrency-and-cleanup.md): Read when: testing timers, retries, fibers, queues, interruption, streams, or finalizers.
- [`references/failures-and-regressions.md`](./references/failures-and-regressions.md): Read when: asserting typed errors, causes, protocol contracts, or a regression.
