---
name: effect-testing
description: Choose cross-cutting Effect test seams and deterministic evidence with layer replacement, logical time, concurrency coordination, typed failures, interruption, and cleanup. Use when those testing decisions are primary; use a protocol specialist for protocol-specific semantics.
---

## Rules

- Run the project’s configured `@effect/tsgo` diagnostics and locally selected automation profiles; this skill covers judgment beyond those checks.
- Test through the public boundary used by a real caller and preserve production composition behind it.
- Replace only external, expensive, nondeterministic, or destructive boundaries.
- Coordinate concurrency with Effect test services and synchronization primitives, not elapsed wall time.
- Assert stable behavioral outcomes, typed failures, protocol effects, and cleanup obligations.

## Constraints

- A fake must implement the same semantic contract as the boundary it replaces.
- Shared test layers may share state; choose sharing only when the suite intends it.
- Live external checks are separately named smoke/integration tests, not normal behavioral tests.

## Knowledge Boundaries

Applies to:

- selecting unit, contract, in-process integration, and live smoke boundaries
- layer replacement and state isolation
- logical time, fibers, queues, deferreds, retries, interruption, and cleanup
- typed success/failure and regression assertions

Does not cover:

- protocol-specific test semantics owned by HTTP, Stream, Platform, AI, Cluster, Workflow, Atom, Layer, or another specialized skill
- property-law and generator design owned by `effect-fast-check`
- mechanically detectable test API misuse
- testing behavior already guaranteed by the compiler or an unwrapped dependency

Decision inputs:

- user-visible or caller-visible contract
- smallest boundary that reproduces the behavior
- nondeterministic capabilities to replace
- coordination point and evidence that the changed path executed

## Patterns

- Build the closest public composition that demonstrates the contract, then replace its true external edges with layers, handler-backed clients, fake spawners, or scoped fixtures.
- Use logical time only after the tested fiber has reached the sleep, timeout, retry, or scheduling point; coordinate readiness explicitly.
- Assert exact calls only when wire shape or invocation is the contract, such as method/path/body, CLI arguments, idempotency key, or cleanup call.
- Assert typed failures through the error/result/exit shape that callers observe. Inspect Cause when defect or interruption classification matters.
- For regression tests, name the broken behavior, reproduce through the public boundary, and assert the stable outcome that prevents recurrence.
- Escalate verification fidelity when transport, middleware, serialization, lifecycle, or runtime behavior is itself under test.

## Gotchas

- Mocking every collaborator proves a duplicate implementation rather than the production graph.
- Advancing TestClock before a child fiber reaches its timer creates a race disguised as a deterministic test.
- Sharing a mutable block layer makes tests order-dependent unless state is reset or sharing is intentional.
- Asserting private refs, queues, cache layout, or incidental call order makes harmless refactors look like regressions.
- An in-memory fake that ignores uniqueness, ordering, transactions, or interruption can validate behavior the real boundary cannot provide.
- A green command without observing the returned value, protocol request, emitted event, or cleanup can miss that the changed code never ran.

## References

- [`references/public-boundaries-and-layers.md`](./references/public-boundaries-and-layers.md): Read when: choosing the test seam, production composition, fake state, or in-process integration boundary.
- [`references/time-concurrency-and-cleanup.md`](./references/time-concurrency-and-cleanup.md): Read when: testing timers, retries, fibers, queues, interruption, streams, or finalizers.
- [`references/failures-and-regressions.md`](./references/failures-and-regressions.md): Read when: asserting typed errors, causes, protocol contracts, or a regression.
